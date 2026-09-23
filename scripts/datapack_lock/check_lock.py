#!/usr/bin/env python3
"""
Fails (non-zero exit) if a pull request touches any file under a
packs/<name>/ directory that is marked "locked": true.

Usage:
    check_lock.py <path-to-lock-json> [changed-file ...]
    check_lock.py <path-to-lock-json> --from-file <path-with-one-file-per-line>

Lock file is read from the path given on the command line. CI should pass
the lock file from the *base* branch (not the PR head) so that unlocking
and editing in the same PR cannot bypass the check.

Design notes:
- A top-level packs/ directory with NO entry in the lock file is treated as
  new content and is allowed (with a NOTE). Add and lock it in a follow-up.
- locked: true → any changed path under that pack fails the job.
- locked: false → changes allowed (maintenance mode).
- Unlock must be a separate merged PR before content edits; evaluating the
  base-branch lock file enforces that.
"""
from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from pathlib import Path


def top_level_pack_name(changed_path: str, packs_prefix: str = "packs/") -> str | None:
    # Normalize separators for Windows-style paths in rare diffs
    changed_path = changed_path.replace("\\", "/")
    if not changed_path.startswith(packs_prefix):
        return None
    rest = changed_path[len(packs_prefix) :]
    if not rest or rest.startswith("."):
        # lock file itself or other dotfiles under packs/ — not a pack
        return None
    parts = rest.split("/", 1)
    if len(parts) < 2:
        # A file directly under packs/ (no subdirectory), e.g.
        # packs/merge-manifest.json — packs are always directories, so a
        # bare top-level file is repo tooling/config, not a pack, and must
        # not be treated as an unlocked "new pack" that skips the lock
        # check entirely.
        return None
    name = parts[0]
    return name if name else None


def load_changed_files(positional: list[str], from_file: str | None) -> list[str]:
    files: list[str] = []
    if from_file is not None:
        path = Path(from_file)
        if path.is_file():
            for line in path.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if line and not line.startswith("#"):
                    files.append(line)
    files.extend(positional)
    # de-dupe, preserve order
    seen: set[str] = set()
    out: list[str] = []
    for f in files:
        if f not in seen:
            seen.add(f)
            out.append(f)
    return out


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Block PR changes to locked datapacks.")
    parser.add_argument(
        "lock_json",
        help="Path to packs/.datapack-lock.json (prefer base-branch copy in CI)",
    )
    parser.add_argument(
        "changed_files",
        nargs="*",
        help="Changed paths (packs/...)",
    )
    parser.add_argument(
        "--from-file",
        dest="from_file",
        default=None,
        help="File with one changed path per line (avoids shell word-splitting)",
    )
    args = parser.parse_args(argv)

    lock_path = Path(args.lock_json)
    if not lock_path.is_file():
        print(f"ERROR: lock file not found: {lock_path}", file=sys.stderr)
        return 2

    try:
        lock_data = json.loads(lock_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        print(f"ERROR: invalid JSON in {lock_path}: {exc}", file=sys.stderr)
        return 2

    packs = lock_data.get("packs")
    if not isinstance(packs, dict):
        print(f"ERROR: {lock_path} missing object key 'packs'", file=sys.stderr)
        return 2

    changed_files = load_changed_files(args.changed_files, args.from_file)
    if not changed_files:
        print("OK: no pack files in the diff.")
        return 0

    packs_prefix = "packs/"
    bare_files = sorted(
        f.replace("\\", "/")[len(packs_prefix):]
        for f in changed_files
        if f.replace("\\", "/").startswith(packs_prefix)
        and top_level_pack_name(f) is None
        and not f.replace("\\", "/")[len(packs_prefix):].startswith(".")
    )
    if bare_files:
        # Files directly under packs/ (not inside any pack directory, and
        # not a dotfile like .datapack-lock.json) are not covered by any
        # lock entry and are NOT blocked by this check, no matter what they
        # do — e.g. packs/merge-manifest.json controls which locked packs'
        # content ends up in the merged output. Flag them loudly so a
        # reviewer notices instead of this passing silently.
        print(
            "NOTE: this PR touches file(s) directly under packs/ that are outside "
            "any pack directory and outside this lock check's scope entirely "
            f"(review manually): {bare_files}"
        )

    touched_by_pack: dict[str, list[str]] = defaultdict(list)
    for changed_file in changed_files:
        pack_name = top_level_pack_name(changed_file)
        if pack_name is None:
            continue
        touched_by_pack[pack_name].append(changed_file)

    violations: list[tuple[str, list[str]]] = []
    new_packs: list[str] = []

    for pack_name, files in sorted(touched_by_pack.items()):
        entry = packs.get(pack_name)
        if entry is None:
            new_packs.append(pack_name)
            continue
        if not isinstance(entry, dict):
            print(
                f"ERROR: lock entry for {pack_name!r} must be an object, got {type(entry).__name__}",
                file=sys.stderr,
            )
            return 2
        if entry.get("locked", False):
            violations.append((pack_name, files))

    if new_packs:
        print(
            "NOTE: new top-level pack director(y/ies) not yet in the lock file "
            f"(allowed through, but should be added and locked in a follow-up PR): "
            f"{sorted(new_packs)}"
        )

    if violations:
        print("\nFAILED: this PR modifies file(s) inside locked pack(s):\n", file=sys.stderr)
        for pack_name, files in violations:
            print(f"  packs/{pack_name}/ (locked: true)", file=sys.stderr)
            for f in files:
                print(f"    - {f}", file=sys.stderr)
        print(
            "\nLocked datapacks are blocked from content changes in the same PR.\n"
            "To edit a locked pack:\n"
            "  1. Open and merge a separate PR that sets its entry to "
            "'locked: false' in packs/.datapack-lock.json\n"
            "  2. Open a PR with your content changes\n"
            "  3. Open a follow-up PR that sets 'locked: true' again\n"
            "Unlocking and editing in one PR is intentionally rejected "
            "(lock status is taken from the base branch).",
            file=sys.stderr,
        )
        return 1

    print("OK: no changes to locked pack content.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
