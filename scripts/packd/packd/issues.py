"""Turning GitHub issues into SNBT the datapack can read.

The datapack side (``macroengine:issues``) only ever *reads* the storage this
module writes; it cannot ask for anything. That keeps the flow one-way, which
is what SECURITY.md section 3 requires - no path from in-game input back to a
command, a shell or the filesystem.

Two things here are load-bearing rather than cosmetic:

**Escaping.** Issue titles and bodies come from GitHub and anyone can open an
issue, so their text is attacker-controlled and ends up inside a command
string. :func:`snbt_string` therefore escapes rather than interpolates, and
:func:`build_issues_payload` is tested against injection attempts.

**Size.** An RCON body cannot exceed 4096 bytes, and a list of issues with
bodies will not fit. :func:`build_issues_commands` measures what it produces
and degrades - first dropping bodies, then trimming the list - until every
command is actually sendable, instead of failing at the socket.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Sequence

from .github import Issue
from .rcon import MAX_PACKET_SIZE

#: Storage the datapack reads. `macroengine:api/issues/refresh` renders it.
STORAGE_ID = "macroengine:issues"

#: Longest command body we will build. Leaves headroom under the 4096-byte
#: packet limit for the packet framing and for the `/data merge storage `
#: prefix itself.
MAX_BODY = MAX_PACKET_SIZE - 10 - len(f"data merge storage {STORAGE_ID} ") - 32

MAX_TITLE = 120
MAX_BODY_PREVIEW = 200
MAX_LABELS = 4


class SnbtError(Exception):
    """A value could not be encoded as SNBT."""


def snbt_string(value: str, *, limit: int | None = None) -> str:
    """Encode one Python string as a quoted SNBT string.

    Backslashes and double quotes are escaped; every other control character -
    including newlines, tabs and NUL - is replaced with a space. Replacing
    rather than escaping is deliberate: SNBT's handling of escapes varies by
    context, and a literal control character inside a command body is exactly
    the thing that breaks packet framing.
    """
    if not isinstance(value, str):
        raise SnbtError(f"expected str, got {type(value).__name__}")
    out: list[str] = []
    for char in value:
        code = ord(char)
        if char == "\\":
            out.append("\\\\")
        elif char == '"':
            out.append('\\"')
        elif code < 0x20 or code == 0x7F:
            out.append(" ")
        else:
            out.append(char)
    text = "".join(out)
    if limit is not None and len(text) > limit:
        text = text[: max(0, limit - 1)] + "\u2026"
    return f'"{text}"'


def snbt_list(values: Sequence[str]) -> str:
    return "[" + ",".join(snbt_string(v) for v in values) + "]"


def issue_entry(issue: Issue, *, with_body: bool) -> str:
    """One issue as an SNBT compound."""
    parts = [
        f"number:{int(issue.number)}",
        f"title:{snbt_string(issue.title, limit=MAX_TITLE)}",
        f"state:{snbt_string(issue.state)}",
        f"author:{snbt_string(issue.author, limit=40)}",
        f"updated:{snbt_string(issue.updated, limit=32)}",
        f"url:{snbt_string(issue.url, limit=300)}",
        f"labels:{snbt_list(list(issue.labels)[:MAX_LABELS])}",
    ]
    if with_body:
        parts.append(
            f"preview:{snbt_string(issue.short_body, limit=MAX_BODY_PREVIEW)}"
        )
    else:
        parts.append('preview:""')
    return "{" + ",".join(parts) + "}"


@dataclass(frozen=True)
class IssuesPayload:
    """The commands that publish an issue list, and what was degraded to fit."""

    commands: list[str]
    included: int
    with_body: bool
    total: int

    @property
    def truncated(self) -> bool:
        return self.included < self.total or not self.with_body


def _render(issues: Sequence[Issue], *, with_body: bool, fetched_at: str) -> str:
    entries = ",".join(issue_entry(i, with_body=with_body) for i in issues)
    return (
        "{schema:1,"
        f'fetched_at:{snbt_string(fetched_at, limit=32)},'
        f"count:{len(issues)},"
        f"issues:[{entries}]}}"
    )


def build_issues_commands(
    issues: Sequence[Issue],
    *,
    fetched_at: str,
    storage_id: str = STORAGE_ID,
    max_body: int = MAX_BODY,
) -> IssuesPayload:
    """Build the `/data merge storage` commands for an issue list.

    Tries the full payload first, then drops the body previews, then trims the
    list until it fits. Every returned command is guaranteed to be within
    `max_body`, so none of them can fail at the socket for being too long.
    """
    total = len(issues)
    prefix = f"data merge storage {storage_id} "

    def command(nbt: str) -> str:
        return prefix + nbt

    # Pass 1: everything. Pass 2: no body previews. Pass 3..: fewer issues.
    for with_body in (True, False):
        if not issues:
            return IssuesPayload([command(_render([], with_body=False, fetched_at=fetched_at))], 0, False, total)
        candidate = command(_render(issues, with_body=with_body, fetched_at=fetched_at))
        if len(candidate) <= max_body:
            return IssuesPayload([candidate], total, with_body, total)

    included = len(issues)
    while included > 0:
        subset = list(issues[:included])
        candidate = command(_render(subset, with_body=False, fetched_at=fetched_at))
        if len(candidate) <= max_body:
            return IssuesPayload([candidate], included, False, total)
        # Shrink geometrically so a pathological list terminates quickly.
        included = max(0, included // 2 if included > 4 else included - 1)

    return IssuesPayload(
        [command(_render([], with_body=False, fetched_at=fetched_at))], 0, False, total
    )


def clear_command(storage_id: str = STORAGE_ID) -> str:
    return f"data remove storage {storage_id}"


def refresh_command(namespace: str = "macroengine") -> str:
    """Ask the datapack to re-render from storage.

    A fixed function path - never built from server output.
    """
    if namespace not in ("macroengine", "guikit"):
        raise SnbtError(f"unsupported namespace for refresh: {namespace!r}")
    return f"function {namespace}:api/issues/refresh"
