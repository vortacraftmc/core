"""Installed-revision state and history.

One JSON file records which commit each managed pack is currently on, plus the
revisions it has been through. That history is what makes rollback possible
without consulting GitHub again, and what lets ``packd status`` say something
true about the server instead of guessing from file dates.

The password is never part of this file - :attr:`packd.config.Config.password`
reads the environment on access precisely so it cannot be serialised by
accident.
"""

from __future__ import annotations

import json
import os
import tempfile
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

STATE_VERSION = 1
DEFAULT_STATE_NAME = ".packd-state.json"
MAX_HISTORY = 20


class StateError(Exception):
    """The state file is unreadable or malformed."""


def _now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


@dataclass
class HistoryEntry:
    sha: str
    installed_at: str
    source: str  # "update", "rollback", "manual", "adopt"
    ref: str = ""

    def to_dict(self) -> dict[str, Any]:
        return {
            "sha": self.sha,
            "installed_at": self.installed_at,
            "source": self.source,
            "ref": self.ref,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any], where: str) -> "HistoryEntry":
        sha = str(data.get("sha", ""))
        if not sha:
            raise StateError(f"{where}: history entry has no sha")
        return cls(
            sha=sha,
            installed_at=str(data.get("installed_at", "")),
            source=str(data.get("source", "")),
            ref=str(data.get("ref", "")),
        )


@dataclass
class PackState:
    """What is known about one installed pack."""

    name: str
    sha: str = ""
    installed_at: str = ""
    ref: str = ""
    history: list[HistoryEntry] = field(default_factory=list)

    @property
    def known(self) -> bool:
        return bool(self.sha)

    @property
    def short_sha(self) -> str:
        return self.sha[:7] if self.sha else "-"

    def to_dict(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "sha": self.sha,
            "installed_at": self.installed_at,
            "ref": self.ref,
            "history": [h.to_dict() for h in self.history],
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any], where: str) -> "PackState":
        name = str(data.get("name", ""))
        if not name:
            raise StateError(f"{where}: pack state has no name")
        history = []
        raw_history = data.get("history") or []
        if not isinstance(raw_history, list):
            raise StateError(f"{where}: history must be a list")
        for i, entry in enumerate(raw_history):
            if not isinstance(entry, dict):
                raise StateError(f"{where}: history[{i}] must be an object")
            history.append(HistoryEntry.from_dict(entry, f"{where}: history[{i}]"))
        return cls(
            name=name,
            sha=str(data.get("sha", "")),
            installed_at=str(data.get("installed_at", "")),
            ref=str(data.get("ref", "")),
            history=history,
        )


@dataclass
class State:
    """The whole state file."""

    path: Path
    packs: dict[str, PackState] = field(default_factory=dict)

    # ------------------------------------------------------------------ I/O

    @classmethod
    def load(cls, path: Path) -> "State":
        if not path.exists():
            return cls(path=path)
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            raise StateError(
                f"{path} is not valid JSON: {exc}. Delete it to start fresh; "
                f"packd will re-detect what is installed."
            ) from None
        except OSError as exc:
            raise StateError(f"cannot read {path}: {exc}") from None
        if not isinstance(data, dict):
            raise StateError(f"{path} must contain a JSON object")
        version = data.get("version")
        if version != STATE_VERSION:
            raise StateError(
                f"{path} is state version {version!r}; this packd reads version "
                f"{STATE_VERSION}. Delete the file to rebuild it."
            )
        packs: dict[str, PackState] = {}
        raw_packs = data.get("packs") or []
        if not isinstance(raw_packs, list):
            raise StateError(f"{path}: 'packs' must be a list")
        for i, entry in enumerate(raw_packs):
            if not isinstance(entry, dict):
                raise StateError(f"{path}: packs[{i}] must be an object")
            pack = PackState.from_dict(entry, f"{path}: packs[{i}]")
            packs[pack.name] = pack
        return cls(path=path, packs=packs)

    def save(self) -> None:
        """Write atomically, so an interrupted write cannot corrupt the file."""
        payload = {
            "version": STATE_VERSION,
            "updated_at": _now(),
            "packs": [p.to_dict() for p in self.packs.values()],
        }
        text = json.dumps(payload, indent=2) + "\n"
        self.path.parent.mkdir(parents=True, exist_ok=True)
        fd, tmp = tempfile.mkstemp(
            dir=str(self.path.parent), prefix=".packd-state-", suffix=".tmp"
        )
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as handle:
                handle.write(text)
            os.replace(tmp, self.path)
        except BaseException:
            try:
                os.unlink(tmp)
            except OSError:
                pass
            raise

    # -------------------------------------------------------------- access

    def get(self, name: str) -> PackState:
        if name not in self.packs:
            self.packs[name] = PackState(name=name)
        return self.packs[name]

    def record(
        self, name: str, sha: str, *, source: str, ref: str = ""
    ) -> PackState:
        """Note that `name` is now on `sha`, keeping bounded history."""
        pack = self.get(name)
        if pack.sha and pack.sha != sha:
            pack.history.insert(
                0,
                HistoryEntry(
                    sha=pack.sha,
                    installed_at=pack.installed_at,
                    source="superseded",
                    ref=pack.ref,
                ),
            )
            del pack.history[MAX_HISTORY:]
        pack.sha = sha
        pack.installed_at = _now()
        pack.ref = ref
        return pack

    def previous_shas(self, name: str) -> list[str]:
        """Revisions this pack has been on, most recent first, excluding the
        current one. This is the rollback menu."""
        pack = self.packs.get(name)
        if pack is None:
            return []
        seen: list[str] = []
        for entry in pack.history:
            if entry.sha and entry.sha != pack.sha and entry.sha not in seen:
                seen.append(entry.sha)
        return seen


def default_state_path(world_dir: Path) -> Path:
    return world_dir / "datapacks" / DEFAULT_STATE_NAME
