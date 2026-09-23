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

--------------------------------------------------------------------------
v2 additions (all opt-in via new flags -- omit every new flag and this
script's behavior, output and exit codes are byte-for-byte identical to
v1; nothing above this line changed):

1. ai_write_locked (per pack, in the lock JSON):
   Blocks merging a PR that touches the pack when the PR shows a sign of
   AI authorship. Enable by passing --commit-actors-json and/or --pr-label.
   check_lock.py never talks to git or GitHub itself -- CI supplies the
   facts as data, same philosophy as --from-file above.

     --commit-actors-json <path>
         JSON file: a list of objects, one per commit in the PR, e.g.
             [{"sha": "abc123...",
               "author_name": "...", "author_email": "...",
               "committer_name": "...", "committer_email": "...",
               "trailers": ["Co-authored-by: Claude <noreply@anthropic.com>"]}]
         A GitHub Actions step can produce this with:
             git log --no-merges --format='%H%x1f%an%x1f%ae%x1f%cn%x1f%ce%x1f%(trailers:only=true,unfold=true,separator=%x1e)%x1d' \
                 "origin/${BASE_REF}..HEAD" | <small python/jq glue, see repo docs>
     --pr-label <label>            (repeatable)
         A label attached to the PR. Anything matching
         /ai[-_ ]?(authored|generated|assisted)/i counts as a signal too,
         for repos that require contributors to self-label AI-assisted PRs.
     --ai-identity-pattern <regex> (repeatable)
         Extra case-insensitive regex(es) recognized as an AI-tool identity
         in commit author/committer/trailer text, added to the built-in
         defaults (bot suffixes, and common assistant/tool names).

   This is a *disclosure and metadata* control, not a technical barrier:
   it catches commits that carry an honest AI signature (bot accounts,
   Co-authored-by trailers, a self-applied PR label). It cannot detect an
   AI-authored change that a human commits under their own identity with
   no trailer -- no automated check can, from metadata alone.

2. ai_read_locked (per pack, in the lock JSON):
   Not something this script can enforce by itself -- nothing server-side
   can stop a local AI tool from opening a file. What CAN be enforced is
   that the ignore-file convention those tools DO honor (.claudeignore,
   .cursorignore, .aiexclude, ...) actually lists every ai_read_locked
   pack, and stays that way. This script owns a single managed block in
   each such file (bounded by BEGIN/END markers) and can check or write it.

     --ai-ignore-files <path> [<path> ...]
         Enables the check. Fails if any listed file is missing the
         managed block, or the block doesn't match the lock file.
     --fix-ai-ignore
         Instead of failing on drift, (re)writes the managed block in each
         --ai-ignore-files path to match the lock file, and exits 0.
         Everything outside the markers is left untouched.

   Honesty note: this raises the bar for compliant tooling and catches
   silent drift between the lock file and the ignore files. It is not a
   sandbox -- a tool (or a person) that doesn't read/respect the ignore
   file is not stopped by it. Treat it as one layer among several
   (branch protection, CODEOWNERS, review), not the only one.

3. Prompt-injection content scan (extends this repo's existing
   no-injection-mode / dpguard philosophy -- see
   scripts/datapack_risk_scan.py for the command-risk counterpart):

     --content-dir <dir>
         Directory mirroring the PR-head content of every changed file
         under packs/, e.g. produced in CI with:
             while read -r f; do
               mkdir -p "$RUNNER_TEMP/content/$(dirname "$f")"
               git show "HEAD:$f" > "$RUNNER_TEMP/content/$f" 2>/dev/null || true
             done < "$RUNNER_TEMP/changed_pack_files.txt"
         Scans every changed .mcfunction line and every .json string leaf
         for (a) phrases that address an AI assistant directly ("ignore
         previous instructions", "you are now an AI", etc.) and (b)
         invisible/zero-width Unicode characters (U+200B, U+200C, U+200D,
         U+2060, U+FEFF, Unicode tag characters) -- a known way to hide
         text from a human reviewer while an AI tool still reads it.
         A hit blocks the merge; a pack can opt out with
         "injection_scan_exempt": true in the lock file (a human should
         still have looked at *why* before adding that).

   Honesty note: this is pattern matching, not proof of intent, and it
   is English-language-biased -- it will miss injection text written in
   Turkish or any other language, and it can false-positive on an
   innocuous broadcast message that happens to contain one of the
   phrases. It raises the cost of hiding an injection in plain sight; it
   does not guarantee there isn't one.

4. Lock-file schema lint (always on, warnings only, never changes the
   exit code): flags unrecognized top-level or per-pack keys so a typo
   like "ai_read_lock" doesn't silently fail to be enforced.

5. --json-summary <path> / --step-summary <path>: machine-readable JSON
   report and a Markdown findings summary (append-mode, safe to point at
   $GITHUB_STEP_SUMMARY) covering every check above, for a PR comment bot
   or the Actions job summary UI.

Exit codes (unchanged meaning, extended scope):
    0 = every requested check passed
    1 = a check ran and found something that should block the merge
        (locked pack edit, ai_write_locked hit, ai-ignore drift,
        injection-scan hit)
    2 = check_lock.py itself couldn't evaluate the input (bad/missing
        lock file, malformed JSON, malformed lock entry)
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path

SCRIPT_VERSION = "2.0.0"

# ---------------------------------------------------------------------------
# v1 logic -- unchanged
# ---------------------------------------------------------------------------


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


# ---------------------------------------------------------------------------
# v2 -- lock-file schema lint (warnings only, never blocks)
# ---------------------------------------------------------------------------

_KNOWN_TOP_LEVEL_KEYS = {"$comment", "packs"}
_KNOWN_PACK_KEYS = {
    "locked",
    "ai_read_locked",
    "ai_write_locked",
    "injection_scan_exempt",
    "$comment",
}


def lint_lock_schema(lock_data: dict, packs: dict) -> None:
    """Warn about keys that don't match the known schema. Never fails the
    build: a stricter schema should never retroactively break a lock file
    nobody has touched, it should just help a human notice a typo like
    "ai_read_lock" that would otherwise silently fail to be enforced."""
    unknown_top = set(lock_data.keys()) - _KNOWN_TOP_LEVEL_KEYS
    if unknown_top:
        print(f"WARN: unrecognized top-level key(s) in lock file: {sorted(unknown_top)}")
    for pack_name, entry in packs.items():
        if not isinstance(entry, dict):
            continue  # reported as a hard error later, where it actually matters
        unknown = set(entry.keys()) - _KNOWN_PACK_KEYS
        if unknown:
            print(
                f"WARN: pack {pack_name!r} has unrecognized lock key(s) "
                f"{sorted(unknown)} -- typo? (ignored, not enforced)"
            )


def _is_injection_exempt(packs: dict, pack_name: str | None) -> bool:
    if pack_name is None:
        return False
    entry = packs.get(pack_name)
    return isinstance(entry, dict) and bool(entry.get("injection_scan_exempt", False))


# ---------------------------------------------------------------------------
# v2 -- ai_write_locked: block merges that carry an AI-authorship signal
# ---------------------------------------------------------------------------

DEFAULT_AI_IDENTITY_PATTERNS: list[str] = [
    r"\[bot\]",
    r"\bclaude\b",
    r"\banthropic\b",
    r"\bcopilot\b",
    r"\bcodex\b",
    r"\bchatgpt\b",
    r"\bgpt-\d",
    r"\bopenai\b",
    r"\bgemini\b",
    r"\bcursor\b",
    r"\bdevin\b",
    r"\bopenhands\b",
    r"\bwindsurf\b",
    r"\bqwen\b",
    r"\bdeepseek\b",
]

_AI_LABEL_PATTERN = re.compile(r"\bai[-_ ]?(authored|generated|assisted)\b", re.IGNORECASE)


@dataclass
class CommitActor:
    sha: str
    author_name: str = ""
    author_email: str = ""
    committer_name: str = ""
    committer_email: str = ""
    trailers: list[str] = field(default_factory=list)


def load_commit_actors(path: str) -> list[CommitActor]:
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(data, list):
        raise ValueError("--commit-actors-json must contain a JSON array")
    actors: list[CommitActor] = []
    for item in data:
        actors.append(
            CommitActor(
                sha=str(item.get("sha", "?")),
                author_name=str(item.get("author_name", "") or ""),
                author_email=str(item.get("author_email", "") or ""),
                committer_name=str(item.get("committer_name", "") or ""),
                committer_email=str(item.get("committer_email", "") or ""),
                trailers=list(item.get("trailers", []) or []),
            )
        )
    return actors


def _actor_ai_match(actor: CommitActor, patterns: list[re.Pattern]) -> str | None:
    haystacks = [
        ("author", actor.author_name),
        ("author email", actor.author_email),
        ("committer", actor.committer_name),
        ("committer email", actor.committer_email),
        *(("trailer", t) for t in actor.trailers),
    ]
    for label, h in haystacks:
        if not h:
            continue
        for p in patterns:
            if p.search(h):
                return f"{label} {h!r} matched /{p.pattern}/"
    return None


def check_ai_write_lock(
    packs: dict,
    touched_by_pack: dict[str, list[str]],
    commit_actors: list[CommitActor],
    pr_labels: list[str],
    extra_patterns: list[str],
) -> list[tuple[str, list[str], list[str]]]:
    """Returns (pack_name, files, reasons) for every ai_write_locked pack
    touched by a PR that carries at least one AI-authorship signal."""
    ai_write_packs = {
        name for name, entry in packs.items() if isinstance(entry, dict) and entry.get("ai_write_locked", False)
    }
    touched_locked = ai_write_packs & touched_by_pack.keys()
    if not touched_locked:
        return []

    patterns = [re.compile(p, re.IGNORECASE) for p in (*DEFAULT_AI_IDENTITY_PATTERNS, *extra_patterns)]

    reasons: list[str] = []
    for actor in commit_actors:
        m = _actor_ai_match(actor, patterns)
        if m:
            reasons.append(f"commit {actor.sha[:12]}: {m}")
    for label in pr_labels:
        if _AI_LABEL_PATTERN.search(label):
            reasons.append(f"PR label {label!r}")

    if not reasons:
        return []

    return [(name, touched_by_pack[name], reasons) for name in sorted(touched_locked)]


# ---------------------------------------------------------------------------
# v2 -- ai_read_locked: keep AI-tool ignore files in sync with the lock file
# ---------------------------------------------------------------------------

_AI_IGNORE_MARK_BEGIN = (
    "# --- BEGIN datapack_lock:ai_read_locked "
    "(auto-generated by scripts/datapack_lock/check_lock.py --fix-ai-ignore; "
    "do not hand-edit this block) ---"
)
_AI_IGNORE_MARK_END = "# --- END datapack_lock:ai_read_locked ---"


def expected_ai_ignore_lines(packs: dict) -> list[str]:
    names = sorted(name for name, entry in packs.items() if isinstance(entry, dict) and entry.get("ai_read_locked", False))
    return [f"packs/{name}/" for name in names]


def _read_managed_block(text: str) -> list[str] | None:
    lines = text.splitlines()
    try:
        start = lines.index(_AI_IGNORE_MARK_BEGIN)
        end = lines.index(_AI_IGNORE_MARK_END, start)
    except ValueError:
        return None
    return lines[start + 1 : end]


def check_ai_ignore_sync(packs: dict, ignore_paths: list[str]) -> list[str]:
    expected = expected_ai_ignore_lines(packs)
    problems: list[str] = []
    if not expected:
        return problems
    for ig_path_str in ignore_paths:
        ig_path = Path(ig_path_str)
        if not ig_path.is_file():
            problems.append(f"{ig_path}: file does not exist (expected entries for: {expected})")
            continue
        block = _read_managed_block(ig_path.read_text(encoding="utf-8"))
        if block is None:
            problems.append(f"{ig_path}: missing managed datapack_lock:ai_read_locked block (run --fix-ai-ignore)")
            continue
        actual = [line for line in block if line.strip() and not line.strip().startswith("#")]
        if sorted(actual) != sorted(expected):
            missing = sorted(set(expected) - set(actual))
            extra = sorted(set(actual) - set(expected))
            detail = []
            if missing:
                detail.append(f"missing: {missing}")
            if extra:
                detail.append(f"stale/extra: {extra}")
            problems.append(f"{ig_path}: out of sync with lock file ({'; '.join(detail)}); run --fix-ai-ignore")
    return problems


def fix_ai_ignore(packs: dict, ignore_paths: list[str]) -> list[str]:
    """Rewrites the managed block in each path to match the lock file.
    Returns the list of paths actually written, for the caller to report."""
    expected = expected_ai_ignore_lines(packs)
    block_lines = [_AI_IGNORE_MARK_BEGIN, *(expected or ["# (no ai_read_locked packs)"]), _AI_IGNORE_MARK_END]
    written: list[str] = []
    for ig_path_str in ignore_paths:
        ig_path = Path(ig_path_str)
        text = ig_path.read_text(encoding="utf-8") if ig_path.is_file() else ""
        lines = text.splitlines()
        existing = _read_managed_block(text)
        if existing is None:
            pad = [""] if lines and lines[-1].strip() else []
            new_lines = [*lines, *pad, *block_lines]
        else:
            start = lines.index(_AI_IGNORE_MARK_BEGIN)
            end = lines.index(_AI_IGNORE_MARK_END, start)
            new_lines = [*lines[:start], *block_lines, *lines[end + 1 :]]
        ig_path.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
        written.append(str(ig_path))
    return written


# ---------------------------------------------------------------------------
# v2 -- prompt-injection content scan
# ---------------------------------------------------------------------------

_INJECTION_PHRASE_PATTERNS = [
    re.compile(r"ignore (all |any )?(the )?(previous|prior|above) instructions", re.IGNORECASE),
    re.compile(r"disregard (all |any |the )?(system |previous |prior )?instructions", re.IGNORECASE),
    re.compile(r"you are (now |actually )?(an? )?(ai|assistant|language model)\b", re.IGNORECASE),
    re.compile(r"\bsystem\s*prompt\b", re.IGNORECASE),
    re.compile(r"\bnew instructions?\s*:", re.IGNORECASE),
    re.compile(r"\bas an ai\b", re.IGNORECASE),
    re.compile(r"\bact as (an? )?(unrestricted|jailbroken|dan)\b", re.IGNORECASE),
    re.compile(r"do not (tell|inform|mention (this|it) to) the (user|developer|reviewer)", re.IGNORECASE),
    re.compile(r"\b(claude|copilot|chatgpt)[,:]?\s+(please\s+)?(run|execute|delete|exfiltrate)\b", re.IGNORECASE),
    re.compile(r"^\s*assistant\s*:\s*\S", re.IGNORECASE | re.MULTILINE),
]

# Zero-width/invisible characters and the Unicode "tag" block, a known way
# to smuggle text past a human eyeballing a diff while a tokenizer/LLM
# still reads it.
_INVISIBLE_UNICODE = re.compile("[\u200b\u200c\u200d\u2060\ufeff\U000e0001\U000e0020-\U000e007f]")


@dataclass
class InjectionHit:
    file: str
    line_no: int
    kind: str  # "phrase" | "invisible_unicode"
    detail: str


def _iter_scannable_strings(path: Path):
    """Yield (line_no, text) pairs worth scanning: every line of a
    .mcfunction file (commands can embed natural-language text via
    tellraw/title JSON, and invisible Unicode doesn't need a comment to
    hide in), and every string leaf of a .json file."""
    suffix = path.suffix.lower()
    try:
        raw = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return
    if suffix == ".mcfunction":
        for i, line in enumerate(raw.splitlines(), start=1):
            yield i, line
    elif suffix == ".json":
        try:
            obj = json.loads(raw)
        except json.JSONDecodeError:
            yield 0, raw
            return

        def walk(o):
            if isinstance(o, str):
                yield o
            elif isinstance(o, dict):
                for v in o.values():
                    yield from walk(v)
            elif isinstance(o, list):
                for v in o:
                    yield from walk(v)

        for s in walk(obj):
            yield 0, s


def scan_content_for_injection(root: Path, relative_paths: list[str]) -> list[InjectionHit]:
    hits: list[InjectionHit] = []
    for rel in relative_paths:
        path = root / rel
        if not path.is_file():
            continue
        for line_no, text in _iter_scannable_strings(path):
            for pat in _INJECTION_PHRASE_PATTERNS:
                if pat.search(text):
                    snippet = text.strip()[:120]
                    hits.append(InjectionHit(rel, line_no, "phrase", f"matched /{pat.pattern}/ -> {snippet!r}"))
            invisible = [c for c in text if _INVISIBLE_UNICODE.match(c)]
            if invisible:
                cps = ", ".join(f"U+{ord(c):04X}" for c in invisible)
                hits.append(
                    InjectionHit(
                        rel,
                        line_no,
                        "invisible_unicode",
                        f"hidden Unicode control/tag character(s) [{cps}] -- classic steganographic prompt-injection technique",
                    )
                )
    return hits


# ---------------------------------------------------------------------------
# v2 -- machine-readable output
# ---------------------------------------------------------------------------


def write_json_summary(path: str, report: dict) -> None:
    Path(path).write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8")


def write_step_summary(path: str, report: dict) -> None:
    ok = not any(
        [
            report["lock_violations"],
            report["ai_write_violations"],
            report["ai_read_ignore_drift"],
            report["injection_hits"],
        ]
    )
    lines = [
        "### Datapack lock check",
        "",
        f"**Result:** {'passed' if ok else 'BLOCKED'}",
        "",
    ]
    if report["lock_violations"]:
        lines.append("**Locked pack edits:**")
        for name, files in report["lock_violations"]:
            lines.append(f"- `packs/{name}/` ({len(files)} file(s))")
    if report["ai_write_violations"]:
        lines.append("**ai_write_locked pack edited with an AI-authorship signal:**")
        for name, _files, reasons in report["ai_write_violations"]:
            lines.append(f"- `packs/{name}/`: {'; '.join(reasons)}")
    if report["ai_read_ignore_drift"]:
        lines.append("**AI-ignore file drift:**")
        for p in report["ai_read_ignore_drift"]:
            lines.append(f"- {p}")
    if report["injection_hits"]:
        lines.append("**Possible prompt-injection content:**")
        for h in report["injection_hits"]:
            loc = f"{h['file']}:{h['line']}" if h["line"] else h["file"]
            lines.append(f"- `{loc}` ({h['kind']}): {h['detail']}")
    with Path(path).open("a", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Block PR changes to locked datapacks, plus opt-in AI guardrails.")
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
    parser.add_argument(
        "--commit-actors-json",
        dest="commit_actors_json",
        default=None,
        help="JSON file of per-commit author/committer/trailer data for this PR. Enables the ai_write_locked check.",
    )
    parser.add_argument(
        "--pr-label",
        dest="pr_labels",
        action="append",
        default=[],
        help="A label on the PR (repeatable). Matches to /ai[-_ ]?(authored|generated|assisted)/i count as an "
        "AI-authorship signal for the ai_write_locked check.",
    )
    parser.add_argument(
        "--ai-identity-pattern",
        dest="ai_identity_patterns",
        action="append",
        default=[],
        help="Extra case-insensitive regex recognized as an AI-tool identity, on top of the built-in defaults. "
        "Repeatable.",
    )
    parser.add_argument(
        "--ai-ignore-files",
        dest="ai_ignore_files",
        nargs="+",
        default=[],
        help="Path(s) to AI-tool ignore files (.claudeignore, .cursorignore, .aiexclude, ...). Enables the "
        "ai_read_locked check.",
    )
    parser.add_argument(
        "--fix-ai-ignore",
        action="store_true",
        help="Rewrite the managed block in --ai-ignore-files to match the lock file instead of checking for drift.",
    )
    parser.add_argument(
        "--content-dir",
        dest="content_dir",
        default=None,
        help="Directory mirroring PR-head content of changed packs/ files. Enables the prompt-injection scan.",
    )
    parser.add_argument(
        "--json-summary",
        dest="json_summary",
        default=None,
        help="Write a machine-readable JSON report of every finding to this path.",
    )
    parser.add_argument(
        "--step-summary",
        dest="step_summary",
        default=None,
        help="Append a Markdown findings summary to this path (point at $GITHUB_STEP_SUMMARY in Actions).",
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

    lint_lock_schema(lock_data, packs)

    report: dict = {
        "script_version": SCRIPT_VERSION,
        "bare_files": [],
        "new_packs": [],
        "lock_violations": [],
        "ai_write_violations": [],
        "ai_read_ignore_drift": [],
        "injection_hits": [],
        "exit_code": 0,
    }

    using_new_features = bool(args.commit_actors_json or args.pr_labels or args.ai_ignore_files or args.content_dir)

    changed_files = load_changed_files(args.changed_files, args.from_file)

    if not changed_files and not using_new_features:
        # Exact v1 behavior/output when called exactly as before.
        print("OK: no pack files in the diff.")
        return 0

    exit_code = 0
    had_lock_check = False
    touched_by_pack: dict[str, list[str]] = defaultdict(list)

    if changed_files:
        had_lock_check = True
        packs_prefix = "packs/"
        bare_files = sorted(
            f.replace("\\", "/")[len(packs_prefix) :]
            for f in changed_files
            if f.replace("\\", "/").startswith(packs_prefix)
            and top_level_pack_name(f) is None
            and not f.replace("\\", "/")[len(packs_prefix) :].startswith(".")
        )
        if bare_files:
            print(
                "NOTE: this PR touches file(s) directly under packs/ that are outside "
                "any pack directory and outside this lock check's scope entirely "
                f"(review manually): {bare_files}"
            )
        report["bare_files"] = bare_files

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
        report["new_packs"] = sorted(new_packs)

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
            exit_code = 1
        report["lock_violations"] = [(name, files) for name, files in violations]

    # --- v2: ai_write_locked -------------------------------------------------
    if args.commit_actors_json or args.pr_labels:
        try:
            commit_actors = load_commit_actors(args.commit_actors_json) if args.commit_actors_json else []
        except (OSError, json.JSONDecodeError, ValueError) as exc:
            print(f"ERROR: could not read --commit-actors-json: {exc}", file=sys.stderr)
            return 2
        ai_write_violations = check_ai_write_lock(
            packs, touched_by_pack, commit_actors, args.pr_labels, args.ai_identity_patterns
        )
        if ai_write_violations:
            print(
                "\nFAILED: this PR modifies file(s) inside ai_write_locked pack(s) "
                "and shows sign(s) of AI authorship:\n",
                file=sys.stderr,
            )
            for pack_name, files, reasons in ai_write_violations:
                print(f"  packs/{pack_name}/ (ai_write_locked: true)", file=sys.stderr)
                for f in files:
                    print(f"    - {f}", file=sys.stderr)
                for r in reasons:
                    print(f"    reason: {r}", file=sys.stderr)
            print(
                "\nai_write_locked datapacks may only be modified by a human-authored, "
                "human-reviewed commit. Have a person make the change directly under "
                "their own identity (no AI co-author trailer, no AI-tool bot account, "
                "no ai-authored/-generated/-assisted label) and open a fresh PR.",
                file=sys.stderr,
            )
            exit_code = 1
        report["ai_write_violations"] = ai_write_violations

    # --- v2: ai_read_locked ignore-file sync ---------------------------------
    if args.ai_ignore_files:
        if args.fix_ai_ignore:
            written = fix_ai_ignore(packs, args.ai_ignore_files)
            for w in written:
                print(f"FIXED: synced managed ai_read_locked block in {w}")
        else:
            drift = check_ai_ignore_sync(packs, args.ai_ignore_files)
            if drift:
                print("\nFAILED: AI-ignore file(s) are out of sync with ai_read_locked packs:\n", file=sys.stderr)
                for p in drift:
                    print(f"  {p}", file=sys.stderr)
                fix_cmd = " ".join(args.ai_ignore_files)
                print(
                    f"\nRun: python3 {sys.argv[0]} {args.lock_json} --ai-ignore-files {fix_cmd} --fix-ai-ignore\n"
                    "then commit the updated file(s). This keeps AI coding tools that "
                    "honor these ignore files from reading ai_read_locked pack content -- "
                    "it cannot stop a tool that doesn't respect the file, so treat it as "
                    "one layer, not the only one.",
                    file=sys.stderr,
                )
                exit_code = 1
            report["ai_read_ignore_drift"] = drift

    # --- v2: prompt-injection content scan -----------------------------------
    if args.content_dir:
        scan_targets = [f for f in changed_files if f.startswith("packs/")]
        raw_hits = scan_content_for_injection(Path(args.content_dir), scan_targets)
        hits = [h for h in raw_hits if not _is_injection_exempt(packs, top_level_pack_name(h.file))]
        if hits:
            print("\nFAILED: possible prompt-injection content detected in changed pack file(s):\n", file=sys.stderr)
            for h in hits:
                loc = f"{h.file}:{h.line_no}" if h.line_no else h.file
                print(f"  [{h.kind}] {loc} -- {h.detail}", file=sys.stderr)
            print(
                "\nThis is a heuristic pattern match, not proof of malicious intent -- "
                "false positives happen. A human must open each flagged line and either "
                "fix the content or, with a stated reason in the PR, set "
                '"injection_scan_exempt": true for that pack in the lock file. Do not '
                "merge on \"looks fine to me\" without opening the flagged line.",
                file=sys.stderr,
            )
            exit_code = 1
        report["injection_hits"] = [
            {"file": h.file, "line": h.line_no, "kind": h.kind, "detail": h.detail} for h in hits
        ]

    if exit_code == 0:
        if had_lock_check:
            print("OK: no changes to locked pack content.")
        else:
            print("OK: all requested datapack_lock checks passed.")

    report["exit_code"] = exit_code
    if args.json_summary:
        write_json_summary(args.json_summary, report)
    if args.step_summary:
        write_step_summary(args.step_summary, report)

    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
