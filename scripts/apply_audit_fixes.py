#!/usr/bin/env python3
"""
Applies the safe, mechanical fixes reported by scripts/audit_repo.py.

Fixes applied (all reversible and tracked by git):
  F1  delete .mcfunction watermark files that ended up inside tags/
  F2  in legacy packs (pack_format < 48) move the watermark from function/ to
      functions/ and remove the directory it leaves empty
  F3  guikit-demo: clear_in -> clear/in, clear_w -> clear/w (broken call sites)
  F4  align merge-manifest output min/max_format with the most demanding pack
  F5  drop the duplicated format fields in LeftClickDetection/pack.mcmeta
  F6  .github/workflows/lint.sh -> scripts/lint_datapacks.sh + update callers
  F7  build.gradle checkOriginWatermarks: validate the location, not just the name
  F8  mark documentation references to workflows that no longer exist

Usage: python3 scripts/apply_audit_fixes.py [--dry-run]
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys


def _root():
    r = subprocess.run(["git", "rev-parse", "--show-toplevel"],
                       capture_output=True, text=True,
                       cwd=os.path.dirname(os.path.abspath(__file__)))
    if r.returncode == 0 and r.stdout.strip():
        return r.stdout.strip()
    return os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


REPO = _root()
DRY = "--dry-run" in sys.argv
LOG: list[str] = []

SINGULAR_FROM_FORMAT = 48


def log(msg):
    LOG.append(msg)
    print(("  [dry] " if DRY else "  ") + msg)


def norm_fmt(f):
    return f[0] if isinstance(f, list) else f


def declared_format(pack_dir):
    p = os.path.join(pack_dir, "pack.mcmeta")
    if not os.path.exists(p):
        return None
    try:
        pk = json.load(open(p, encoding="utf-8")).get("pack", {})
    except (json.JSONDecodeError, OSError):
        return None
    for k in ("min_format", "pack_format"):
        if k in pk:
            return norm_fmt(pk[k])
    return None


def walk_files(top):
    for root, dirs, files in os.walk(top):
        dirs[:] = [d for d in dirs if d != "build"]
        for f in files:
            yield os.path.join(root, f)


def rm(path):
    log(f"DELETE {os.path.relpath(path, REPO)}")
    if not DRY:
        os.remove(path)


def mv(src, dst):
    log(f"MOVE   {os.path.relpath(src, REPO)} -> {os.path.relpath(dst, REPO)}")
    if not DRY:
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.move(src, dst)


def rmdir_if_empty(d):
    try:
        if os.path.isdir(d) and not os.listdir(d):
            log(f"RMDIR  (empty) {os.path.relpath(d, REPO)}")
            if not DRY:
                os.rmdir(d)
    except OSError:
        pass


def rewrite(path, pairs, label):
    txt = open(path, encoding="utf-8").read()
    new, n = txt, 0
    for a, b in pairs:
        c = new.count(a)
        if c:
            new = new.replace(a, b)
            n += c
    if n:
        log(f"EDIT   {os.path.relpath(path, REPO)}  ({n} change(s): {label})")
        if not DRY:
            open(path, "w", encoding="utf-8").write(new)
    return n


# --------------------------------------------------------------------------- #
def f1_tags_stray():
    """Delete provenance watermarks that were written into tags/ directories."""
    print("\nF1 - .mcfunction watermark files inside tags/")
    packs = os.path.join(REPO, "packs")
    n = 0
    for root, dirs, files in os.walk(packs):
        dirs[:] = [d for d in dirs if d != "build"]
        if os.path.basename(root) not in ("function", "functions"):
            continue
        if f"{os.sep}tags{os.sep}" not in root + os.sep:
            continue
        for f in files:
            if not f.endswith(".mcfunction"):
                continue
            fp = os.path.join(root, f)
            pack_root = fp.split(f"{os.sep}data{os.sep}")[0]
            keep = [x for x in walk_files(pack_root)
                    if os.path.basename(x) == "_vc_origin.mcfunction"
                    and f"{os.sep}tags{os.sep}" not in x]
            if not keep:
                log(f"SKIP   {os.path.relpath(fp, REPO)} - the pack has no other "
                    "correctly placed watermark")
                continue
            rm(fp)
            n += 1
    print(f"  -> {n} file(s)")
    return n


def f2_legacy_fn_dir():
    """Move watermarks into the directory the pack's pack_format actually uses."""
    print("\nF2 - move watermark function/ -> functions/ in legacy packs")
    packs = os.path.join(REPO, "packs")
    moved = 0
    for pack in sorted(os.listdir(packs)):
        pdir = os.path.join(packs, pack)
        if not os.path.isdir(pdir):
            continue
        fmt = declared_format(pdir)
        if fmt is None:
            for root, _dirs, files in os.walk(pdir):
                if "pack.mcmeta" in files:
                    fmt = declared_format(root)
                    if fmt is not None:
                        break
        if fmt is None or fmt >= SINGULAR_FROM_FORMAT:
            continue
        data = os.path.join(pdir, "data")
        if not os.path.isdir(data):
            continue
        for ns in sorted(os.listdir(data)):
            nsd = os.path.join(data, ns)
            sing, plur = os.path.join(nsd, "function"), os.path.join(nsd, "functions")
            if not (os.path.isdir(sing) and os.path.isdir(plur)):
                continue
            for f in sorted(os.listdir(sing)):
                src = os.path.join(sing, f)
                if not os.path.isfile(src):
                    continue
                dst = os.path.join(plur, f)
                if os.path.exists(dst):
                    log(f"CONFLICT {os.path.relpath(dst, REPO)} already exists - deleting source")
                    rm(src)
                else:
                    mv(src, dst)
                moved += 1
            rmdir_if_empty(sing)
    print(f"  -> {moved} file(s) moved")
    return moved


def f3_guikit_refs():
    """Fix calls to functions that were moved into a subdirectory."""
    print("\nF3 - guikit-demo broken function references")
    demo = os.path.join(REPO, "packs", "guikit-demo")
    pairs = [("guikit:internal/clear_in", "guikit:internal/clear/in"),
             ("guikit:internal/clear_w", "guikit:internal/clear/w")]
    total = 0
    for fp in walk_files(demo):
        if fp.endswith(".mcfunction"):
            total += rewrite(fp, pairs, "clear_in->clear/in, clear_w->clear/w")
    print(f"  -> {total} call site(s) fixed")
    return total


def f4_manifest():
    """Stop the merged pack from under-declaring its format requirement."""
    print("\nF4 - merge-manifest output format")
    mp = os.path.join(REPO, "packs", "merge-manifest.json")
    mm = json.load(open(mp, encoding="utf-8"))
    packs = os.path.join(REPO, "packs")
    need = None
    for inc in mm.get("include", []):
        p = os.path.join(packs, inc, "pack.mcmeta")
        if not os.path.exists(p):
            continue
        pk = json.load(open(p, encoding="utf-8")).get("pack", {})
        raw = pk.get("min_format", pk.get("pack_format"))
        if isinstance(raw, list) and (need is None or raw > need):
            need = raw
    out = mm.get("output", {})
    if need and out.get("min_format") != need:
        log(f"EDIT   packs/merge-manifest.json  output.min/max_format "
            f"{out.get('min_format')} -> {need}")
        if not DRY:
            out["min_format"] = list(need)
            out["max_format"] = list(need)
            mm["output"] = out
            with open(mp, "w", encoding="utf-8") as fh:
                json.dump(mm, fh, indent=2, ensure_ascii=False)
                fh.write("\n")
        return 1
    print("  -> no change needed")
    return 0


def f5_leftclick_meta():
    """pack.mcmeta declared the same format four different ways."""
    print("\nF5 - LeftClickDetection pack.mcmeta format duplication")
    p = os.path.join(REPO, "packs", "LeftClickDetection", "pack.mcmeta")
    m = json.load(open(p, encoding="utf-8"))
    pk = m.get("pack", {})
    # Only act when the redundant aliases are actually still there, so the fix
    # is idempotent and re-running it does not rewrite an already clean file.
    if "pack_format" in pk and ("min_format" in pk or "max_format" in pk):
        kept = {"description": pk.get("description")}
        for k in ("pack_format", "supported_formats"):
            if k in pk:
                kept[k] = pk[k]
        log("EDIT   packs/LeftClickDetection/pack.mcmeta  dropped min/max_format "
            "(pack_format + supported_formats already carry the same information)")
        if not DRY:
            m["pack"] = {k: v for k, v in kept.items() if v is not None}
            with open(p, "w", encoding="utf-8") as fh:
                json.dump(m, fh, indent=2, ensure_ascii=False)
                fh.write("\n")
        return 1
    print("  -> no change needed")
    return 0


def f6_move_lint():
    """A shell script does not belong in .github/workflows/."""
    print("\nF6 - lint script location")
    src = os.path.join(REPO, ".github", "workflows", "lint.sh")
    dst = os.path.join(REPO, "scripts", "lint_datapacks.sh")
    if not os.path.exists(src):
        print("  -> already moved")
        return 0
    if DRY:
        log("MOVE   .github/workflows/lint.sh -> scripts/lint_datapacks.sh")
    else:
        subprocess.run(["git", "mv", src, dst], cwd=REPO, check=True)
        log("MOVE   .github/workflows/lint.sh -> scripts/lint_datapacks.sh")
    n = 0
    p = os.path.join(REPO, ".github", "workflows", "build.yml")
    if os.path.exists(p):
        n += rewrite(p, [(".github/workflows/lint.sh", "scripts/lint_datapacks.sh")],
                     "lint.sh path")
    for fp in walk_files(REPO):
        if fp.endswith(".md") and f"{os.sep}.git{os.sep}" not in fp:
            rewrite(fp, [(".github/workflows/lint.sh", "scripts/lint_datapacks.sh")],
                    "lint.sh path")
    print(f"  -> {n} workflow reference(s)")
    return 1


def f7_watermark_check():
    """checkOriginWatermarks promised a location check but only checked the name."""
    print("\nF7 - checkOriginWatermarks location validation")
    bg = os.path.join(REPO, "build.gradle")
    txt = open(bg, encoding="utf-8").read()
    old = """        def hasWatermark = false
        dir.eachFileRecurse { f ->
            if (f.name == '_vc_origin.mcfunction') {
                hasWatermark = true
            }
        }
        !hasWatermark"""
    new = """        // The location is validated too. The error message promises a watermark
        // "under data/<namespace>/function/", but the previous code accepted one
        // anywhere in the pack - a stray copy inside tags/function/ was enough to
        // pass. Only files under the correct tree are counted now.
        def hasWatermark = false
        def dataDir = new File(dir, 'data')
        if (dataDir.exists()) {
            dataDir.eachFileRecurse { f ->
                if (f.name != '_vc_origin.mcfunction') return
                def rel = dataDir.toPath().relativize(f.toPath()).toString()
                def parts = rel.split(java.util.regex.Pattern.quote(File.separator))
                // <namespace>/function(s)/...  (pack_format < 48 uses 'functions')
                if (parts.length >= 3 && (parts[1] == 'function' || parts[1] == 'functions')) {
                    hasWatermark = true
                }
            }
        }
        !hasWatermark"""
    if old in txt:
        log("EDIT   build.gradle  findMissingWatermarks now validates the location")
        if not DRY:
            open(bg, "w", encoding="utf-8").write(txt.replace(old, new))
        return 1
    if "parts[1] == 'function'" in txt:
        print("  -> already applied")
        return 0
    print("  !! expected code block not found, skipped")
    return 0


def f8_workflow_refs():
    """Annotate references to workflows that belonged to the pre-monorepo org."""
    print("\nF8 - references to workflows that do not exist")
    targets = {
        os.path.join(REPO, "scripts", "dp-depman", "README.md"):
            ("datapack-build.yml", "dep-update.yml"),
        os.path.join(REPO, "scripts", "dp-depman", "docs", "README.md"):
            ("datapack-build.yml", "dep-update.yml"),
        os.path.join(REPO, "scripts", "gui_generator", "README.md"):
            ("publish.yml",),
    }
    n = 0
    for p, names in targets.items():
        if not os.path.exists(p):
            continue
        txt = open(p, encoding="utf-8").read()
        lines = txt.splitlines(keepends=True)
        changed = 0
        out = []
        for line in lines:
            if any(x in line for x in names) and "(retired" not in line:
                line = line.rstrip("\n").rstrip() + "  (retired, pre-monorepo)\n"
                changed += 1
            out.append(line)
        if changed:
            log(f"EDIT   {os.path.relpath(p, REPO)}  ({changed} line(s) annotated)")
            if not DRY:
                open(p, "w", encoding="utf-8").write("".join(out))
            n += 1
    print(f"  -> {n} document(s)")
    return n


# --------------------------------------------------------------------------- #
def main():
    print("=" * 70)
    print("BULK FIX" + ("  [DRY-RUN]" if DRY else ""))
    print("=" * 70)
    totals = {}
    for fn in (f1_tags_stray, f2_legacy_fn_dir, f3_guikit_refs, f4_manifest,
               f5_leftclick_meta, f6_move_lint, f7_watermark_check, f8_workflow_refs):
        totals[fn.__name__] = fn()
    print("\n" + "=" * 70)
    print("SUMMARY: " + ", ".join(f"{k}={v}" for k, v in totals.items()))
    print(f"{len(LOG)} operation(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
