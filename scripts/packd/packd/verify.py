"""Reading server replies back as data.

Everything here is a *parser*. Nothing in this module returns a command, and no
caller feeds its output into :meth:`packd.rcon.RconClient.command`. That
distinction is the whole point: SECURITY.md section 3 forbids any bridge from
server or in-game output to a shell, a path or a command, and section 4 forbids
the same for RCON specifically. A reply is text to be reported, never an
instruction to be obeyed.

Parsers here fail soft. ``/datapack list`` renders as a text component whose
exact shape varies by server implementation and version, so an answer we cannot
interpret returns :data:`TriState.UNKNOWN` rather than a confident "no" - a
false negative would make the tool report a broken install that is fine.
"""

from __future__ import annotations

import enum
import re


class TriState(enum.Enum):
    YES = "yes"
    NO = "no"
    UNKNOWN = "unknown"

    def __bool__(self) -> bool:  # pragma: no cover - convenience
        return self is TriState.YES


_SCORE_RE = re.compile(r"(-?\d+)")
#: A pack name may contain letters, digits, `_`, `-` and `.`, so a prefix match
#: is not enough: `file/demo-extra` contains `file/demo`. The name has to be
#: followed by something that cannot be part of a name, or by end of text.
_NAME_BOUNDARY = r"(?![A-Za-z0-9_.\-])"


def datapack_state(reply: str, pack_name: str) -> TriState:
    """Is `pack_name` present in a ``/datapack list`` reply?

    Looks for the pack as a resource location (``file/<name>``) or as a quoted
    name, both of which appear in the component Minecraft returns. Returns
    UNKNOWN when the reply does not look like a datapack list at all, so the
    caller can say "could not confirm" instead of "failed".

    Matching is on the whole name, not a prefix: a substring test would report
    ``demo`` as installed when only ``demo-extra`` was, which is exactly the
    kind of false "it worked" this check exists to prevent.
    """
    if not reply:
        return TriState.UNKNOWN
    text = reply.replace("\\/", "/")
    looks_like_list = ("datapack" in text.lower()) or ("file/" in text) or ("[" in text and "]" in text)
    if not looks_like_list:
        return TriState.UNKNOWN
    escaped = re.escape(pack_name)
    patterns = (
        rf"file/{escaped}{_NAME_BOUNDARY}",
        rf'"{escaped}"',
    )
    for pattern in patterns:
        if re.search(pattern, text):
            return TriState.YES
    # The name may appear with its directory stripped or as part of a longer
    # component; only claim NO when we did see a list and the name is absent.
    return TriState.NO


def storage_int(reply: str) -> int | None:
    """Extract the integer from a ``/data get`` or ``scoreboard players get``
    reply, or None if there is no number in it."""
    if not reply:
        return None
    match = _SCORE_RE.search(reply)
    return int(match.group(1)) if match else None


def reload_ok(reply: str) -> TriState:
    """Did ``/reload`` appear to succeed?

    `/reload` answers with an empty body on success and with an error message
    on failure, so an empty reply is the good case.
    """
    text = (reply or "").strip().lower()
    if not text:
        return TriState.YES
    if "error" in text or "unknown" in text or "incorrect" in text or "failed" in text:
        return TriState.NO
    return TriState.UNKNOWN


def command_error(reply: str) -> str | None:
    """A short error description if the reply looks like one, else None."""
    text = (reply or "").strip()
    if not text:
        return None
    lowered = text.lower()
    for marker in ("unknown or incomplete command", "incorrect argument", "failed to", "error"):
        if marker in lowered:
            return text.splitlines()[0][:200]
    return None


def summarise(reply: str, *, limit: int = 200) -> str:
    """First line of a reply, for display. Never re-executed."""
    text = (reply or "").strip()
    if not text:
        return "(no output)"
    first = text.splitlines()[0]
    return first if len(first) <= limit else first[: limit - 1] + "\u2026"
