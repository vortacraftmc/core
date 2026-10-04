#!/usr/bin/env python3
"""Validate archived/archive.json (stdlib only, no network, no code execution).

Checks: schema shape, unique ids, date format, that `path` exists when set,
that `successor` names a pack under packs/ when set, and that archived paths
are NOT also present under packs/ (so zipPacks/checkPacks never ship them).
Also mirrors the Gradle `checkArchive` task: an archived id/folder must not
still be listed in packs/merge-manifest.json "include", a project cannot be
its own successor, and malformed entries (non-object project, non-list
`known_issues`, non-string `path`/`successor`) are reported as errors instead
of crashing the script. Exit code 1 on any error.
"""
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REG = ROOT / "archived" / "archive.json"
REQUIRED = ["id", "name", "kind", "status", "archived_on", "reason",
            "last_version", "license", "deploy", "successor"]
KINDS = {"datapack", "mod", "resourcepack", "script", "other"}
STATUS = {"archived", "frozen", "superseded"}
DEPLOY = {"not_recommended", "review_required", "ok"}
ALLOWED = set(REQUIRED) | {"minecraft", "path", "source_url", "known_issues"}

def merge_manifest_includes() -> set:
    """Lower-cased entries of packs/merge-manifest.json "include" (empty if absent/unreadable)."""
    mf = ROOT / "packs" / "merge-manifest.json"
    try:
        inc = json.loads(mf.read_text(encoding="utf-8")).get("include", [])
    except Exception:
        return set()
    return {str(x).lower() for x in inc} if isinstance(inc, list) else set()


def main() -> int:
    errs = []
    try:
        data = json.loads(REG.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"[check_archive] cannot read {REG}: {e}")
        return 1
    if not isinstance(data, dict):
        print("[check_archive] ERROR top level must be an object")
        return 1
    if data.get("schema_version") != 1:
        errs.append("schema_version must be 1")
    projects = data.get("projects")
    if not isinstance(projects, list):
        print("[check_archive] ERROR 'projects' must be an array")
        return 1
    packs_root = ROOT / "packs"
    live_dirs = ({d.name.lower() for d in packs_root.iterdir() if d.is_dir()}
                 if packs_root.is_dir() else set())
    included = merge_manifest_includes()
    seen = set()
    for i, p in enumerate(projects):
        if not isinstance(p, dict):
            errs.append(f"projects[{i}]: must be an object")
            continue
        tag = f"projects[{i}] ({p.get('id', '?')})"
        for k in REQUIRED:
            if k not in p:
                errs.append(f"{tag}: missing '{k}'")
        for k in p:
            if k not in ALLOWED:
                errs.append(f"{tag}: unknown field '{k}'")
        if p.get("id") in seen:
            errs.append(f"{tag}: duplicate id")
        seen.add(p.get("id"))
        if not re.fullmatch(r"[a-z0-9][a-z0-9._-]*", str(p.get("id", ""))):
            errs.append(f"{tag}: bad id")
        if p.get("kind") not in KINDS: errs.append(f"{tag}: bad kind")
        if p.get("status") not in STATUS: errs.append(f"{tag}: bad status")
        if p.get("deploy") not in DEPLOY: errs.append(f"{tag}: bad deploy")
        if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", str(p.get("archived_on", ""))):
            errs.append(f"{tag}: archived_on must be YYYY-MM-DD")
        if p.get("known_issues") is not None and not isinstance(p["known_issues"], list):
            errs.append(f"{tag}: known_issues must be an array")
        names = {str(p.get("id", "")).lower()}
        path = p.get("path")
        if path is not None and not isinstance(path, str):
            errs.append(f"{tag}: path must be a string or null")
        elif path:
            rp = (ROOT / path).resolve()
            if ROOT not in rp.parents:
                errs.append(f"{tag}: path escapes repo")
            elif not rp.exists():
                errs.append(f"{tag}: path '{path}' does not exist")
            elif "packs" in Path(path).parts[:1]:
                errs.append(f"{tag}: archived project must not live under packs/")
            names.add(rp.name.lower())
        for n in sorted(n for n in names if n):
            if n in live_dirs:
                errs.append(f"{tag}: '{n}' is still present under packs/ (move or remove it)")
            if n in included:
                errs.append(f"{tag}: '{n}' is still in merge-manifest include")
        succ = p.get("successor")
        if succ is not None and not isinstance(succ, str):
            errs.append(f"{tag}: successor must be a string or null")
        elif succ:
            if succ == p.get("id"):
                errs.append(f"{tag}: successor cannot be itself")
            elif not (ROOT / "packs" / succ).exists():
                print(f"[check_archive] warn: {tag}: successor '{succ}' not found under packs/ (ok if sparse checkout)")
    for e in errs:
        print(f"[check_archive] ERROR {e}")
    print(f"[check_archive] {len(seen)} project(s), {len(errs)} error(s)")
    return 1 if errs else 0

if __name__ == "__main__":
    sys.exit(main())
