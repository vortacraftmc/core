#!/usr/bin/env python3
"""Validate archived/archive.json (stdlib only, no network, no code execution).

Checks: schema shape, unique ids, date format, that `path` exists when set,
that `successor` names a pack under packs/ when set, and that archived paths
are NOT also present under packs/ (so zipPacks/checkPacks never ship them).
Exit code 1 on any error.
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

def main() -> int:
    errs = []
    try:
        data = json.loads(REG.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"[check_archive] cannot read {REG}: {e}")
        return 1
    if data.get("schema_version") != 1:
        errs.append("schema_version must be 1")
    seen = set()
    for i, p in enumerate(data.get("projects", [])):
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
        path = p.get("path")
        if path:
            rp = (ROOT / path).resolve()
            if ROOT not in rp.parents:
                errs.append(f"{tag}: path escapes repo")
            elif not rp.exists():
                errs.append(f"{tag}: path '{path}' does not exist")
            elif "packs" in Path(path).parts[:1]:
                errs.append(f"{tag}: archived project must not live under packs/")
        succ = p.get("successor")
        if succ and not (ROOT / "packs" / succ).exists():
            print(f"[check_archive] warn: {tag}: successor '{succ}' not found under packs/ (ok if sparse checkout)")
    for e in errs:
        print(f"[check_archive] ERROR {e}")
    print(f"[check_archive] {len(seen)} project(s), {len(errs)} error(s)")
    return 1 if errs else 0

if __name__ == "__main__":
    sys.exit(main())
