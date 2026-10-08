#!/usr/bin/env python3
"""Normalise the `$` macro-line prefix across every .mcfunction in the repo.

Minecraft rule
--------------
A line in a .mcfunction is a *macro line* only when it starts with `$`.
Macro substitution then replaces every `$(name)` in it. A `$` prefix on a
line that contains no `$(name)` is a load error ("Expected at least one
macro line variable"), and the reverse is worse: a line containing
`$(name)` without the prefix ships the literal text `$(name)` to the game.

The trap is that scoreboard fake players also start with `$`
(`$mcmd_cond_ok macroengine.tmp`). Those are not macro variables, so a
line using only fake players must NOT be prefixed.

What this does
--------------
For every non-comment line:
  * contains `$(...)`  -> line must start with `$`
  * no `$(...)`        -> line must not start with `$`

Idempotent, and reports every line it changes.

Usage
-----
    python3 scripts/fix_macro_lines.py                 # report only
    python3 scripts/fix_macro_lines.py --fix           # rewrite in place
    python3 scripts/fix_macro_lines.py --root packs/X  # limit the scan
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

MACRO_VAR = re.compile(r"\$\(")


def classify(line: str) -> tuple[str, str] | None:
    """Return (kind, stripped_line) when the prefix is wrong, else None.

    kind is "missing" (needs a `$`) or "stray" (has one it should not).
    """
    stripped = line.strip()

    if not stripped or stripped.startswith("#"):
        return None

    body = line.lstrip()
    has_prefix = body.startswith("$")
    content = body[1:] if has_prefix else body
    needs_prefix = bool(MACRO_VAR.search(content))

    if needs_prefix and not has_prefix:
        return "missing", stripped
    if has_prefix and not needs_prefix:
        return "stray", stripped
    return None


def process(path: Path, fix: bool) -> list[tuple[int, str, str]]:
    findings: list[tuple[int, str, str]] = []
    original = path.read_text(encoding="utf-8", errors="replace")
    out_lines = []

    for lineno, line in enumerate(original.splitlines(), 1):
        verdict = classify(line)
        if verdict is None:
            out_lines.append(line)
            continue

        kind, shown = verdict
        findings.append((lineno, kind, shown))

        if not fix:
            out_lines.append(line)
            continue

        indent = line[: len(line) - len(line.lstrip())]
        body = line.lstrip()
        if kind == "missing":
            out_lines.append(f"{indent}${body}")
        else:
            out_lines.append(f"{indent}{body[1:].lstrip()}")

    if fix and findings:
        newline = "\n" if original.endswith("\n") or not original else ""
        path.write_text("\n".join(out_lines) + newline, encoding="utf-8")

    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".", help="directory to scan (default: repo root)")
    parser.add_argument("--fix", action="store_true", help="rewrite files in place")
    parser.add_argument(
        "--exclude",
        action="append",
        default=["build/", "archived/"],
        help="path fragments to skip (repeatable)",
    )
    args = parser.parse_args()

    root = Path(args.root)
    if not root.is_dir():
        print(f"error: {root} is not a directory", file=sys.stderr)
        return 2

    total = 0
    files_changed = 0

    for path in sorted(root.rglob("*.mcfunction")):
        posix = path.as_posix()
        if any(fragment in posix for fragment in args.exclude):
            continue

        findings = process(path, args.fix)
        if not findings:
            continue

        files_changed += 1
        total += len(findings)
        print(f"{posix}")
        for lineno, kind, shown in findings:
            label = "needs $" if kind == "missing" else "drop  $"
            print(f"  {lineno:>5}  {label}  {shown[:110]}")

    verb = "fixed" if args.fix else "would fix"
    print()
    print(f"{verb} {total} line(s) in {files_changed} file(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
