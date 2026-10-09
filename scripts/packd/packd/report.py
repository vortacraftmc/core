"""Rendering a pack's status for a human.

Shared by `check` and `update` so the two describe a pack identically - they
had separate output paths, and the one that mattered (`check`, the default
command) printed only a total, so "2 packs have an update available" arrived
without saying which packs or what had changed.
"""

from __future__ import annotations

from typing import Callable, Sequence

from .updater import PackStatus

MAX_COMMITS_SHOWN = 5


def describe(entry: PackStatus, log: Callable[[str], None] = print) -> None:
    """Print one pack's status: the revision gap and the commits in between."""
    name = entry.pack.name or "(unknown)"
    if entry.error:
        log(f"  ! {name}: {entry.error}")
        return

    current = entry.installed_sha[:7] if entry.installed_sha else "(not installed)"
    latest = entry.latest_sha[:7] if entry.latest_sha else "(unknown)"

    if entry.error or not entry.latest_sha:
        log(f"  ? {name}: no upstream revision resolved")
        return

    if not entry.update_available:
        log(f"  = {name}: up to date ({current})")
        return

    gap = f"{entry.behind_count} commit(s)" if entry.behind_count else "a newer revision"
    log(f"  ^ {name}: {current} -> {latest} ({gap})")
    for commit in entry.behind[:MAX_COMMITS_SHOWN]:
        log(f"      {commit.short_sha} {commit.subject}")
    if entry.behind_count > MAX_COMMITS_SHOWN:
        log(f"      ... and {entry.behind_count - MAX_COMMITS_SHOWN} more")


def describe_all(
    statuses: Sequence[PackStatus], log: Callable[[str], None] = print
) -> int:
    """Print every pack and return how many have an update available."""
    outdated = 0
    for entry in statuses:
        describe(entry, log)
        if entry.update_available:
            outdated += 1
    return outdated
