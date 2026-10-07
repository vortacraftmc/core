#!/usr/bin/env python3
"""
vortacraftmc/core - repository consistency audit tool.

Usage:
    python3 scripts/audit_repo.py            # human-readable report
    python3 scripts/audit_repo.py --json     # machine-readable findings
    python3 scripts/audit_repo.py --fix      # apply the safe automatic fixes

Every finding is a dict:
    {id, severity, path, line, msg, autofix}

Severities: critical | high | medium | low | info
`autofix` marks findings that --fix can repair mechanically.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from collections import defaultdict


def _find_root():
    """The script lives in scripts/; walk up to the repository root."""
    d = os.path.dirname(os.path.abspath(__file__))
    for _ in range(6):
        if os.path.isdir(os.path.join(d, ".git")) and os.path.isdir(os.path.join(d, "packs")):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            break
        d = parent
    r = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True)
    if r.returncode == 0 and r.stdout.strip():
        return r.stdout.strip()
    return os.path.dirname(os.path.abspath(__file__))


REPO = _find_root()
FINDINGS: list[dict] = []

# --------------------------------------------------------------------------- #
# helpers
# --------------------------------------------------------------------------- #


def add(fid, severity, path, msg, line=None, autofix=False, fix=None):
    FINDINGS.append(
        {
            "id": fid,
            "severity": severity,
            "path": os.path.relpath(path, REPO) if path else None,
            "line": line,
            "msg": msg,
            "autofix": autofix,
            "fix": fix,
        }
    )


def rel(p):
    return os.path.relpath(p, REPO)


def walk(top, exts=None, skip_dirs=(".git", "build", ".gradle", "node_modules")):
    start = top if os.path.isabs(top) else os.path.join(REPO, top)
    for root, dirs, files in os.walk(start):
        dirs[:] = [d for d in dirs if d not in skip_dirs]
        for f in files:
            if exts is None or os.path.splitext(f)[1] in exts:
                yield os.path.join(root, f)


def read_json(p):
    try:
        with open(p, encoding="utf-8") as fh:
            return json.load(fh), None
    except json.JSONDecodeError as e:
        return None, f"invalid JSON: {e}"
    except OSError as e:
        return None, f"unreadable: {e}"


def read_text(p):
    try:
        with open(p, encoding="utf-8", errors="replace") as fh:
            return fh.read()
    except OSError:
        return ""


def sh(args, cwd=REPO):
    r = subprocess.run(args, cwd=cwd, capture_output=True, text=True)
    return r.returncode, r.stdout, r.stderr


# --------------------------------------------------------------------------- #
# 1. pack integrity
# --------------------------------------------------------------------------- #

MC_NS_RE = re.compile(r"^[a-z0-9_.\-]+$")
FORMAT_KEYS = ("pack_format", "min_format", "max_format")

# Minecraft renamed `functions/` -> `function/` and `tags/functions/` ->
# `tags/function/` in 1.21 (pack_format 48). Packs declaring an older format
# must keep the plural spelling, so both have to be accepted.
SINGULAR_FROM_FORMAT = 48


def norm_fmt(f):
    if isinstance(f, list):
        return f[0]
    return f


def audit_packs():
    packs_root = os.path.join(REPO, "packs")
    if not os.path.isdir(packs_root):
        add("pack.missing-root", "critical", "packs", "the packs/ directory does not exist")
        return {}

    pack_info = {}
    pack_hashes = defaultdict(list)

    for entry in sorted(os.listdir(packs_root)):
        pdir = os.path.join(packs_root, entry)
        if not os.path.isdir(pdir):
            continue

        meta_path = os.path.join(pdir, "pack.mcmeta")
        info = {"dir": entry, "path": pdir, "namespaces": [], "functions": 0, "files": 0,
                "format": None, "format_raw": {}}
        pack_info[entry] = info

        for _r, _d, fs in os.walk(pdir):
            info["files"] += len(fs)

        # --- pack.mcmeta ---
        if not os.path.exists(meta_path):
            nested = []
            for r, _d, fs in os.walk(pdir):
                if "pack.mcmeta" in fs:
                    nested.append(os.path.relpath(os.path.join(r, "pack.mcmeta"), REPO))
            if nested:
                add(
                    "pack.mcmeta-nested",
                    "high",
                    pdir,
                    "no top-level pack.mcmeta; found nested at "
                    f"{', '.join(nested)} - this directory is not directly loadable as a datapack",
                )
            else:
                add(
                    "pack.mcmeta-missing",
                    "high",
                    pdir,
                    f"no pack.mcmeta ({info['files']} files) - not a loadable datapack",
                )
        else:
            meta, err = read_json(meta_path)
            if err:
                add("pack.mcmeta-invalid", "critical", meta_path, err)
            else:
                pack = (meta or {}).get("pack", {})
                if not pack.get("description"):
                    add("pack.mcmeta-nodesc", "medium", meta_path, "pack.description is empty")
                present = [k for k in FORMAT_KEYS if k in pack]
                if not present:
                    add(
                        "pack.mcmeta-noformat",
                        "high",
                        meta_path,
                        f"no format field (expected one of {'/'.join(FORMAT_KEYS)})",
                    )
                else:
                    lo = norm_fmt(pack.get("min_format", pack.get("pack_format")))
                    hi = norm_fmt(pack.get("max_format", pack.get("pack_format")))
                    if lo is not None and hi is not None and lo > hi:
                        add("pack.format-reversed", "critical", meta_path,
                            f"min_format({lo}) > max_format({hi})")
                    if "pack_format" in pack and ("min_format" in pack or "max_format" in pack):
                        add(
                            "pack.format-mixed",
                            "medium",
                            meta_path,
                            "both pack_format and min/max_format are declared for the same information",
                        )
                info["format"] = pack.get("min_format", pack.get("pack_format"))
                info["format_raw"] = {k: pack[k] for k in present}

        # --- namespace / data layout ---
        data_dir = os.path.join(pdir, "data")
        declared = norm_fmt(info["format_raw"].get("min_format")) or norm_fmt(
            info["format_raw"].get("pack_format")
        )
        if os.path.isdir(data_dir):
            for ns in sorted(os.listdir(data_dir)):
                ns_dir = os.path.join(data_dir, ns)
                if not os.path.isdir(ns_dir):
                    continue
                if not MC_NS_RE.match(ns):
                    add("pack.ns-invalid", "high", ns_dir,
                        f"namespace '{ns}' is invalid (expected {MC_NS_RE.pattern})")
                info["namespaces"].append(ns)

                have_singular = os.path.isdir(os.path.join(ns_dir, "function"))
                have_plural = os.path.isdir(os.path.join(ns_dir, "functions"))
                for fn_name in ("function", "functions"):
                    fn_dir = os.path.join(ns_dir, fn_name)
                    if os.path.isdir(fn_dir):
                        for _f in walk(fn_dir, {".mcfunction"}):
                            info["functions"] += 1

                if have_singular and have_plural and declared is not None:
                    correct = "function" if declared >= SINGULAR_FROM_FORMAT else "functions"
                    dead = "functions" if correct == "function" else "function"
                    dead_n = len(list(walk(os.path.join(ns_dir, dead), {".mcfunction"})))
                    if dead_n:
                        add(
                            "pack.fn-dir-both",
                            "high",
                            ns_dir,
                            f"both 'function/' and 'functions/' exist; pack_format={declared} means "
                            f"the game only reads '{correct}/', so the {dead_n} file(s) in "
                            f"'{dead}/' are dead",
                        )

                tags_dir = os.path.join(ns_dir, "tags")
                if os.path.isdir(tags_dir):
                    t_sub = [d for d in os.listdir(tags_dir)
                             if os.path.isdir(os.path.join(tags_dir, d))]
                    if "function" in t_sub and "functions" in t_sub and declared is not None:
                        correct = "function" if declared >= SINGULAR_FROM_FORMAT else "functions"
                        add(
                            "pack.tag-dir-both",
                            "high",
                            tags_dir,
                            f"both 'tags/function' and 'tags/functions' exist; "
                            f"pack_format={declared} means 'tags/{correct}' is the correct one",
                        )
                    for s in walk(tags_dir, {".mcfunction"}):
                        add(
                            "pack.mcfunction-in-tags",
                            "high",
                            s,
                            "a .mcfunction file sits inside tags/ - tags/ holds only .json, "
                            "so the game never loads this file",
                            autofix=True,
                            fix=("delete-file", rel(s)),
                        )
                    for tagroot, _d, fs in os.walk(tags_dir):
                        for tf in fs:
                            if not tf.endswith(".json"):
                                continue
                            tp = os.path.join(tagroot, tf)
                            tj, terr = read_json(tp)
                            if terr:
                                add("pack.tag-invalid", "critical", tp, terr)
                                continue
                            if not isinstance(tj, dict):
                                add("pack.tag-notobj", "high", tp, "tag file is not a JSON object")
                                continue
                            if "values" not in tj:
                                add("pack.tag-novalues", "medium", tp, "missing 'values' field")
                            elif not isinstance(tj["values"], list):
                                add("pack.tag-values-notlist", "high", tp, "'values' is not a list")

        # --- provenance watermarks ---
        for f in walk(pdir, {".mcfunction"}):
            if os.path.basename(f) == "_rt_origin.mcfunction":
                add(
                    "pack.watermark-wrong-name",
                    "medium",
                    f,
                    "watermark is named '_rt_origin.mcfunction'; build.gradle only looks for "
                    "'_vc_origin.mcfunction', so this file is never counted",
                )

        # --- content fingerprint, to spot duplicate packs ---
        h = hashlib.sha256()
        for f in sorted(walk(pdir)):
            h.update(rel(f).encode())
            try:
                h.update(open(f, "rb").read())
            except OSError:
                pass
        info["hash"] = h.hexdigest()[:16]
        pack_hashes[h.hexdigest()[:16]].append(entry)

    for _k, names in pack_hashes.items():
        if len(names) > 1:
            add("pack.exact-duplicate", "critical", "packs",
                f"identical content in multiple packs: {', '.join(names)}")

    return pack_info


# --------------------------------------------------------------------------- #
# 2. mcfunction reference resolution
# --------------------------------------------------------------------------- #

FUNC_CALL_RE = re.compile(r"(?<![\w:#$])function\s+([a-z0-9_.\-]+:[a-z0-9_./\-]+)", re.I)
TAG_REF_RE = re.compile(r"#([a-z0-9_.\-]+:[a-z0-9_./\-]+)")


def audit_function_refs(pack_info):
    """Report `function` and `#tag` references that resolve to nothing."""
    per_pack = {}
    global_funcs = set()
    per_pack_tags = defaultdict(set)
    global_tags = set()

    for name, info in pack_info.items():
        ids = set()
        data_dir = os.path.join(info["path"], "data")
        if os.path.isdir(data_dir):
            for ns in os.listdir(data_dir):
                for fn_name in ("function", "functions"):
                    fn_dir = os.path.join(data_dir, ns, fn_name)
                    if os.path.isdir(fn_dir):
                        for f in walk(fn_dir, {".mcfunction"}):
                            rid = rel(f)[len(rel(fn_dir)) + 1: -len(".mcfunction")]
                            ids.add(f"{ns}:{rid}")
                tags_root = os.path.join(data_dir, ns, "tags")
                if os.path.isdir(tags_root):
                    # index every tag category (function, entity_type, item, block, ...)
                    for f in walk(tags_root, {".json"}):
                        sub = rel(f)[len(rel(tags_root)) + 1: -len(".json")]
                        parts = sub.split("/")
                        cat, rid = parts[0], "/".join(parts[1:])
                        if not rid:
                            continue
                        key = f"{ns}:{rid}"
                        per_pack_tags[name].add(key)
                        global_tags.add(key)
                        if cat == "entity_type":
                            per_pack_tags[name].add(f"#{key}")
                            global_tags.add(f"#{key}")
        per_pack[name] = ids
        global_funcs |= ids

    def check_scope(scope_funcs, scope_tags, files):
        missing_f = defaultdict(list)
        missing_t = defaultdict(list)
        for fp in files:
            txt = read_text(fp)
            for i, line in enumerate(txt.splitlines(), 1):
                if line.strip().startswith("#"):
                    continue
                for m in FUNC_CALL_RE.finditer(line):
                    tgt = m.group(1)
                    if tgt.startswith("minecraft:"):
                        continue
                    tail = line[m.end(): m.end() + 2]
                    # macro / dynamic targets cannot be resolved statically
                    if "$" in tgt or "%" in tgt or tail.startswith("$") or tail.startswith("%"):
                        continue
                    tgt = tgt.rstrip("/")
                    if not tgt or tgt not in scope_funcs:
                        missing_f[tgt].append((fp, i))
                for m in TAG_REF_RE.finditer(line):
                    tgt = m.group(1)
                    if tgt.startswith("minecraft:"):
                        continue
                    if tgt not in scope_tags and f"#{tgt}" not in scope_tags:
                        missing_t[tgt].append((fp, i))
        return missing_f, missing_t

    packs_root = os.path.join(REPO, "packs")
    mm, _ = read_json(os.path.join(packs_root, "merge-manifest.json"))
    merged, merged_tags, merged_files = set(), set(), []
    if isinstance(mm, dict):
        for inc in mm.get("include", []):
            base = inc.split("/")[-1]
            merged |= per_pack.get(base, set())
            merged_tags |= per_pack_tags.get(base, set())
            d = os.path.join(packs_root, inc)
            if os.path.isdir(d):
                merged_files += list(walk(d, {".mcfunction"}))

    mf, mt = check_scope(merged, merged_tags, merged_files)
    for tgt, locs in sorted(mf.items()):
        add("mcfunc.dangling-merged", "high", rel(locs[0][0]),
            f"unresolvable 'function {tgt}' in the merge set ({len(locs)} site(s))",
            line=locs[0][1])
    for tgt, locs in sorted(mt.items()):
        add("mcfunc.dangling-tag-merged", "medium", rel(locs[0][0]),
            f"unresolvable tag '#{tgt}' in the merge set ({len(locs)} site(s))",
            line=locs[0][1])

    for name, info in sorted(pack_info.items()):
        if not info["namespaces"]:
            continue
        files = list(walk(info["path"], {".mcfunction"}))
        if not files:
            continue
        scope = per_pack[name] | global_funcs
        tags = per_pack_tags[name] | global_tags
        mf2, _mt2 = check_scope(scope, tags, files)
        for tgt, locs in sorted(mf2.items()):
            add("mcfunc.dangling", "medium", rel(locs[0][0]),
                f"[{name}] unresolvable 'function {tgt}' ({len(locs)} site(s))",
                line=locs[0][1])


# --------------------------------------------------------------------------- #
# 3. mods
# --------------------------------------------------------------------------- #

FABRIC_REQUIRED = ("schemaVersion", "id", "name", "version")


def audit_mods():
    mod_dirs = [os.path.dirname(f) for f in walk(REPO, {"fabric.mod.json"})]
    seen_ids = defaultdict(list)

    for md in sorted(mod_dirs):
        fp = os.path.join(md, "fabric.mod.json")
        meta, err = read_json(fp)
        if err:
            add("mod.fabric-invalid", "critical", fp, err)
            continue
        for k in FABRIC_REQUIRED:
            if k not in meta:
                add("mod.fabric-missing-field", "high", fp, f"required field missing: {k}")
        mid = meta.get("id")
        if mid:
            seen_ids[mid].append(rel(md))
            if not re.match(r"^[a-z][a-z0-9_\-]{0,63}$", str(mid)):
                add("mod.id-invalid", "medium", fp,
                    f"mod id '{mid}' does not match Fabric's id rules")
        if not meta.get("license"):
            add("mod.no-license-field", "medium", fp, "no 'license' field in fabric.mod.json")
        if not (os.path.exists(os.path.join(md, "LICENSE"))
                or os.path.exists(os.path.join(md, "LICENSE.txt"))):
            add("mod.no-license-file", "low", md, "no LICENSE file")

        bg = os.path.join(md, "build.gradle")
        if os.path.exists(bg):
            txt = read_text(bg)
            if "shared-fabric-mod.gradle" not in txt:
                add("mod.no-buildlogic", "medium", bg,
                    "does not apply build-logic/shared-fabric-mod.gradle")
            for m in re.finditer(r'apply from:\s*"\$\{projectDir\}([^"]+)"', txt):
                cand = os.path.normpath(os.path.join(md, m.group(1).strip()))
                if not os.path.exists(cand):
                    add("mod.applyfrom-missing", "critical", bg,
                        f"apply from target does not exist: {m.group(1)}")

        rp = rel(md)
        if rp.startswith("packs" + os.sep):
            add("mod.under-packs", "high", md,
                "a Fabric mod lives under packs/ - NOTICE.md defines mods/ for mods and "
                "packs/ for datapacks, so this placement breaks that contract")

    for mid, locs in seen_ids.items():
        if len(locs) > 1:
            add("mod.duplicate-id", "critical", "mods",
                f"mod id '{mid}' is used in more than one place: {', '.join(locs)}")
    return mod_dirs


# --------------------------------------------------------------------------- #
# 4. manifest / lock / registry coherence
# --------------------------------------------------------------------------- #


def audit_registries(pack_info):
    packs_root = os.path.join(REPO, "packs")

    mm_path = os.path.join(packs_root, "merge-manifest.json")
    mm, err = read_json(mm_path)
    if err:
        add("registry.merge-invalid", "critical", mm_path, err)
    elif isinstance(mm, dict):
        inc = mm.get("include", [])
        if not inc and mm.get("allowEmpty") is not True:
            add("registry.merge-empty", "high", mm_path, "'include' is empty and allowEmpty is not true")
        out_fmt_raw = mm.get("output", {}).get("min_format")
        sub_ver_dropped = []
        for i in inc:
            d = os.path.join(packs_root, i)
            if not os.path.isdir(d):
                add("registry.merge-missing-pack", "critical", mm_path,
                    f"included pack does not exist: {i}")
                continue
            mp = os.path.join(d, "pack.mcmeta")
            if not os.path.exists(mp):
                add("registry.merge-pack-no-mcmeta", "high", mm_path,
                    f"included '{i}' has no pack.mcmeta")
                continue
            meta, _e = read_json(mp)
            raw = (meta or {}).get("pack", {}).get("min_format")
            if isinstance(raw, list) and len(raw) > 1 and raw[1] not in (0, None):
                if not (isinstance(out_fmt_raw, list) and out_fmt_raw == raw):
                    sub_ver_dropped.append((i, raw))
        if sub_ver_dropped:
            add(
                "registry.merge-subversion-dropped",
                "medium",
                mm_path,
                "output min_format drops the sub-version: "
                + ", ".join(f"{i} min_format={raw} -> output {out_fmt_raw}"
                            for i, raw in sub_ver_dropped)
                + " (build.gradle's normalizeFormat takes only f[0] of a list, so the "
                "mismatch guard cannot catch it and the merged pack under-declares its requirement)",
            )

    lock_path = os.path.join(packs_root, ".datapack-lock.json")
    lock, err = read_json(lock_path)
    if err:
        add("registry.lock-invalid", "critical", lock_path, err)
    elif isinstance(lock, dict):
        for pname in (lock.get("packs") or {}):
            if not os.path.isdir(os.path.join(packs_root, pname)):
                add("registry.lock-stale-entry", "medium", lock_path,
                    f"lock entry exists but the directory does not: {pname}")

    arch_path = os.path.join(REPO, "archived", "archive.json")
    arch, err = read_json(arch_path)
    if err:
        add("registry.archive-invalid", "critical", arch_path, err)
    elif isinstance(arch, dict):
        for prj in arch.get("projects", []):
            p = prj.get("path")
            if p and not os.path.exists(os.path.join(REPO, p)):
                add("registry.archive-bad-path", "high", arch_path,
                    f"archive.json path does not exist: {p}")
            if prj.get("status") == "archived" and p and p.startswith("packs"):
                add("registry.archive-still-live", "high", arch_path,
                    f"'{prj.get('id')}' is marked archived but still lives under packs/")


# --------------------------------------------------------------------------- #
# 5. CI / workflows
# --------------------------------------------------------------------------- #

MUTABLE_REF_RE = re.compile(r"uses:\s*([\w.\-/]+)@(main|master|develop|latest)\b")


def audit_ci():
    wf_dir = os.path.join(REPO, ".github", "workflows")
    if not os.path.isdir(wf_dir):
        add("ci.no-workflows", "high", ".github/workflows", "no workflows directory")
        return
    try:
        import yaml
    except ImportError:
        add("ci.no-yaml-lib", "info", None, "PyYAML not installed, workflow parsing skipped")
        yaml = None

    for f in sorted(os.listdir(wf_dir)):
        fp = os.path.join(wf_dir, f)
        if not f.endswith((".yml", ".yaml")):
            if os.path.isfile(fp):
                add("ci.script-in-workflows", "low", fp,
                    f"an executable script lives in the workflows directory ({f}); "
                    "scripts/ is the more consistent home for it")
            continue

        txt = read_text(fp)
        if yaml:
            try:
                doc = yaml.safe_load(txt)
                if not isinstance(doc, dict):
                    add("ci.not-mapping", "critical", fp, "workflow is not a YAML mapping")
                    continue
                if True not in doc and "on" not in doc:
                    add("ci.no-trigger", "high", fp, "no 'on:' trigger")
                jobs = doc.get("jobs", {})
                if not jobs:
                    add("ci.no-jobs", "high", fp, "'jobs:' is empty")
                for jname, job in (jobs or {}).items():
                    if "permissions" not in job and "permissions" not in doc:
                        add("ci.no-permissions", "medium", fp,
                            f"neither job '{jname}' nor the workflow declares 'permissions'")
                    for st in job.get("steps", []) or []:
                        u = st.get("uses")
                        if u and not re.match(r"^[\w.\-/]+@(v\d+(\.\d+)*|[0-9a-f]{40})$", str(u)):
                            add("ci.unpinned-action", "high", fp,
                                f"action is not pinned to a version: {u}")
            except Exception as e:  # noqa: BLE001
                add("ci.yaml-invalid", "critical", fp, f"YAML parse error: {e}")

        for m in MUTABLE_REF_RE.finditer(txt):
            add("ci.mutable-ref", "high", fp, f"mutable ref: {m.group(0).strip()}")

        # No-op detection: a lint script that always exits 0 combined with
        # `continue-on-error` can never fail the build.
        if "continue-on-error: true" in txt:
            script = None
            for cand in ("lint.sh", "lint_datapacks.sh"):
                for base in (wf_dir, os.path.join(REPO, "scripts")):
                    c = os.path.join(base, cand)
                    if os.path.exists(c):
                        script = c
                        break
                if script:
                    break
            if script and re.search(r"^exit 0\s*$", read_text(script), re.M):
                add("ci.noop-lint", "high", script,
                    "the lint script ends in an unconditional 'exit 0' AND its step is "
                    "'continue-on-error: true' - the datapack lint can never fail a build")

        for m in re.finditer(r"(?:bash|sh|python3?)\s+([.\w/\-]+\.(?:sh|py))", txt):
            if not os.path.exists(os.path.join(REPO, m.group(1))):
                add("ci.missing-script", "high", fp,
                    f"workflow invokes a file that does not exist: {m.group(1)}")


# --------------------------------------------------------------------------- #
# 6. documentation
# --------------------------------------------------------------------------- #

GRADLE_TASK_RE = re.compile(r"\./gradlew\s+([a-zA-Z][\w\-]*)")

# Provided by Gradle or by a plugin rather than by tasks.register, so they are
# legitimate even though build.gradle never declares them.
GRADLE_BUILTIN = {
    "build", "clean", "assemble", "check", "test", "jar", "run", "runClient",
    "runServer", "runClientGameTest", "runProductionClientGameTest", "runGameTest",
    "publish", "tasks", "help", "dependencies", "wrapper",
}


def slug(h):
    h = re.sub(r"[`*_]", "", h.strip().lower())
    return "".join(c for c in h if c.isalnum() or c in "-_ ").replace(" ", "-")


def headings(path):
    hs, infence = {}, False
    for line in read_text(path).splitlines():
        if line.lstrip().startswith("```"):
            infence = not infence
            continue
        if infence:
            continue
        m = re.match(r"^(#{1,6})\s+(.*)$", line)
        if m:
            hs.setdefault(slug(m.group(2)), 0)
    return hs


def _all_repo_files():
    return list(walk(REPO))


def audit_docs():
    link_re = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
    for p in walk(REPO, {".md"}):
        txt = re.sub(r"<!--.*?-->", "", read_text(p), flags=re.S)
        base = os.path.dirname(p)
        for i, line in enumerate(txt.splitlines(), 1):
            for target in link_re.findall(line):
                if target.startswith(("http://", "https://")):
                    path, _, frag = target.partition("#")
                    m = re.match(r"https://github\.com/vortacraftmc/core(?:/(?:blob|tree)/[^/]+)?(/.*)?$", path)
                    if not m:
                        continue
                    if "/security/advisories" in path or "/new/" in path:
                        continue
                    tgt = os.path.normpath(
                        os.path.join(REPO, (m.group(1) or "/README.md").lstrip("/") or "README.md"))
                elif target.startswith("#"):
                    tgt, frag = p, target[1:]
                else:
                    path, _, frag = target.partition("#")
                    tgt = os.path.normpath(os.path.join(base, path))
                if not os.path.exists(tgt):
                    add("docs.broken-link", "medium", p, f"broken link: {target}", line=i)
                    continue
                if frag and tgt.endswith(".md") and frag not in headings(tgt):
                    add("docs.broken-anchor", "medium", p, f"broken anchor: {target}", line=i)

    gradle_txt = read_text(os.path.join(REPO, "build.gradle"))
    defined = set(re.findall(r"tasks\.register\(\s*['\"]([\w\-]+)['\"]", gradle_txt))
    defined |= set(re.findall(r"^\s*task\s+([\w\-]+)", gradle_txt, re.M))
    for p in walk(REPO, {".md"}):
        txt = re.sub(r"<!--.*?-->", "", read_text(p), flags=re.S)
        for i, line in enumerate(txt.splitlines(), 1):
            for m in GRADLE_TASK_RE.finditer(line):
                t = m.group(1)
                if t in GRADLE_BUILTIN:
                    continue
                if t not in defined:
                    add("docs.unknown-gradle-task", "high", p,
                        f"documented Gradle task is not defined: {t}", line=i)

    wf_names = set()
    wf_dir = os.path.join(REPO, ".github", "workflows")
    if os.path.isdir(wf_dir):
        wf_names = set(os.listdir(wf_dir))
    gh_dir = os.path.join(REPO, ".github")
    if os.path.isdir(gh_dir):
        wf_names |= {f for f in os.listdir(gh_dir) if f.endswith((".yml", ".yaml"))}
    for p in walk(REPO, {".md", ".json"}):
        txt = re.sub(r"<!--.*?-->", "", read_text(p), flags=re.S)
        for i, line in enumerate(txt.splitlines(), 1):
            low = line.lower()
            # skip lines that already state the file does not exist / is retired
            if any(k in low for k in ("does not exist", "do **not** exist", "historical note",
                                      "does **not** exist", "not exist in", "retired")):
                continue
            for m in re.finditer(r"([\w\-]+\.yml)", line):
                n = m.group(1)
                if n in wf_names:
                    continue
                add("docs.unknown-workflow", "high", p,
                    f"references a workflow that does not exist: {n}", line=i)


# --------------------------------------------------------------------------- #
# 7. git hygiene
# --------------------------------------------------------------------------- #

SECRET_PATTERNS = [
    (re.compile(r"github_pat_[A-Za-z0-9_]{20,}"), "GitHub fine-grained PAT"),
    (re.compile(r"ghp_[A-Za-z0-9]{36}"), "GitHub classic PAT"),
    (re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"), "private key"),
    (re.compile(r"AKIA[0-9A-Z]{16}"), "AWS access key"),
]

MEANINGLESS_MESSAGES = {"", ".", "..", "-", "update", "fix", "wip", "asdf", "test", "a", "aa"}


def audit_git():
    rc, out, _ = sh(["git", "rev-list", "--count", "HEAD"])
    total = int(out.strip()) if rc == 0 else 0

    rc, out, _ = sh(["git", "log", "--pretty=%H%x09%s"])
    if rc == 0:
        bad = []
        for line in out.splitlines():
            h, _, subj = line.partition("\t")
            s = subj.strip()
            if s.lower() in MEANINGLESS_MESSAGES:
                bad.append((h[:7], s or "(empty)"))
        if bad:
            add("git.meaningless-commits", "medium", None,
                f"{len(bad)}/{total} commit message(s) are meaningless: "
                + ", ".join(f"{h} '{s}'" for h, s in bad[:12])
                + ("..." if len(bad) > 12 else ""))

    rc, out, _ = sh(["git", "ls-files", "-z"])
    if rc == 0:
        big = []
        for f in filter(None, out.split("\0")):
            fp = os.path.join(REPO, f)
            if os.path.isfile(fp) and os.path.getsize(fp) > 1_000_000:
                big.append((f, os.path.getsize(fp)))
        for f, sz in sorted(big, key=lambda x: -x[1])[:5]:
            add("git.large-file", "low", f,
                f"{sz / 1e6:.1f} MB - consider Git LFS or external storage")

    for p in walk(REPO):
        txt = read_text(p)
        for rx, label in SECRET_PATTERNS:
            if rx.search(txt):
                add("git.secret-in-tree", "critical", p,
                    f"possible secret in the working tree: {label}")

    rc, out, _ = sh(["git", "for-each-ref",
                     "--format=%(refname:short)\t%(committerdate:unix)\t%(subject)",
                     "refs/remotes/origin"])
    if rc == 0:
        now = time.time()
        _rc, merged_out, _ = sh(["git", "branch", "-r", "--merged", "origin/main"])
        merged = set(merged_out.split())
        for line in out.splitlines():
            parts = line.split("\t")
            if len(parts) < 3:
                continue
            name, ts, _subj = parts
            if name in ("origin/main", "origin/HEAD", "origin"):
                continue
            _rc2, ahead, _ = sh(["git", "rev-list", "--count", f"origin/main..{name}"])
            is_merged = name in merged
            age = (now - float(ts)) / 86400
            if is_merged or age > 14:
                add("git.stale-branch", "medium", None,
                    f"stale branch '{name}': {age:.1f} day(s) old, merged={is_merged}, "
                    f"ahead={ahead.strip()}",
                    autofix=True, fix=("delete-remote-branch", name))

    rc, out, _ = sh(["git", "for-each-ref", "--format=%(refname:short)", "refs/remotes/origin"])
    if rc == 0:
        for name in out.splitlines():
            if name in ("origin/main", "origin/HEAD"):
                continue
            base = name.split("/")[-1]
            if any(k in base for k in ("rollback", "undo", "revert")):
                add("git.rollback-branch", "high", None,
                    f"'{name}' exists to roll main back - the repository is directionally "
                    "undecided; it should either be merged or deleted")


# --------------------------------------------------------------------------- #
# 8. README versus what is on disk
# --------------------------------------------------------------------------- #


def audit_readme_structure(pack_info):
    readme = read_text(os.path.join(REPO, "README.md"))
    documented = {d.rstrip("/") for d in re.findall(r"^-\s+`([^`]+)`", readme, re.M)}
    actual = {d for d in os.listdir(REPO)
              if os.path.isdir(os.path.join(REPO, d)) and not d.startswith(".")}
    for d in sorted(documented):
        top = d.split("/")[0]
        if top.endswith((".md", ".sh", ".py", ".png", ".json")):
            continue
        if not os.path.isdir(os.path.join(REPO, top)):
            add("docs.phantom-dir", "high", "README.md",
                f"README documents a directory that does not exist: `{d}`")
    for d in sorted(actual):
        if d in ("build", "out", "gradle"):
            continue
        if d not in documented:
            add("docs.undocumented-dir", "low", "README.md",
                f"directory not documented in the README Structure section: `{d}/`")


# --------------------------------------------------------------------------- #
# fixes
# --------------------------------------------------------------------------- #


def apply_fixes():
    applied = []
    for f in FINDINGS:
        if not f.get("autofix") or not f.get("fix"):
            continue
        kind, arg = f["fix"]
        if kind == "delete-remote-branch":
            name = arg.replace("origin/", "", 1)
            rc, _out, err = sh(["git", "push", "origin", "--delete", name])
            applied.append((name, "deleted" if rc == 0 else f"FAILED: {err.strip()[:120]}"))
    return applied


# --------------------------------------------------------------------------- #

ORDER = {"critical": 0, "high": 1, "medium": 2, "low": 3, "info": 4}
ICONS = {"critical": "x", "high": "^", "medium": "o", "low": "-", "info": "i"}


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--json", action="store_true", help="emit findings as JSON")
    ap.add_argument("--fix", action="store_true", help="apply the safe automatic fixes")
    args = ap.parse_args()

    pack_info = audit_packs()
    audit_function_refs(pack_info)
    audit_mods()
    audit_registries(pack_info)
    audit_ci()
    audit_docs()
    audit_git()
    audit_readme_structure(pack_info)

    FINDINGS.sort(key=lambda f: (ORDER[f["severity"]], f["id"], f["path"] or ""))

    if args.json:
        print(json.dumps([{k: v for k, v in f.items() if k != "fix"} for f in FINDINGS],
                         ensure_ascii=False, indent=2))
        return 0

    counts = defaultdict(int)
    for f in FINDINGS:
        counts[f["severity"]] += 1

    print("=" * 78)
    print("vortacraftmc/core AUDIT REPORT")
    print("=" * 78)
    print(f"packs: {len(pack_info)}  |  findings: {len(FINDINGS)}  |  "
          + "  ".join(f"{ICONS[k]} {k}: {counts[k]}" for k in ORDER if counts[k]))
    print("=" * 78)

    by_id = defaultdict(list)
    for f in FINDINGS:
        by_id[f["id"]].append(f)

    for fid in sorted(by_id, key=lambda k: (ORDER[by_id[k][0]["severity"]], k)):
        items = by_id[fid]
        sev = items[0]["severity"]
        print(f"\n{ICONS[sev]} [{sev.upper()}] {fid}  ({len(items)})")
        for f in items[:40]:
            loc = f["path"] or "-"
            if f["line"]:
                loc += f":{f['line']}"
            print(f"    {loc}\n      {f['msg']}")
        if len(items) > 40:
            print(f"    ... and {len(items) - 40} more")

    n_fix = sum(1 for f in FINDINGS if f.get("autofix"))
    print("\n" + "=" * 78)
    print(f"auto-fixable: {n_fix}  |  needs a human decision: {len(FINDINGS) - n_fix}")

    if args.fix:
        print("\napplying fixes...")
        for name, res in apply_fixes():
            print(f"  {name}: {res}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
