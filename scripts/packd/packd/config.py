"""Configuration for packd.

The RCON password is **never** read from a config file. SECURITY.md section 4
requires it to come from a secret store or an environment variable and to be
neither committed nor printed, so this module only ever looks in the
environment, and its own ``__repr__`` hides the value.

Everything else lives in ``packd.toml`` next to the server's world folder (or
wherever ``--config`` points). Missing file, missing keys and malformed values
all produce a specific message rather than a traceback.
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

# Update modes, in increasing order of autonomy.
MODE_CHECK = "check"      # report only; never touch the server or the files
MODE_APPROVE = "approve"  # report, then apply only after an explicit yes
MODE_AUTO = "auto"        # apply without asking
VALID_MODES = (MODE_CHECK, MODE_APPROVE, MODE_AUTO)

#: The mode used when nothing is configured. Check-only, so that installing the
#: tool cannot by itself change a running server - which is what SECURITY.md
#: section 4 means by "RCON is disabled by default".
DEFAULT_MODE = MODE_CHECK

PASSWORD_ENV = "PACKD_RCON_PASSWORD"
TOKEN_ENV = "GITHUB_TOKEN"

DEFAULT_HOST = "127.0.0.1"
DEFAULT_RCON_PORT = 25575

#: Packs the tool knows how to update out of the box. A pack is identified by
#: its directory under ``packs/`` in the monorepo, which is also the name it
#: gets inside ``<world>/datapacks/``.
DEFAULT_PACKS: tuple[str, ...] = (
    "macroEngine-Datapack-v26.4",
    "guikit-datapack",
)

REPO_OWNER = "vortacraftmc"
REPO_NAME = "core"


class ConfigError(Exception):
    """The configuration is missing, unreadable or invalid."""


@dataclass
class PackConfig:
    """One managed datapack."""

    name: str
    #: Path of the pack inside the repository, relative to the repo root.
    repo_path: str
    #: Directory name inside <world>/datapacks/. Defaults to the pack name.
    install_as: str = ""
    enabled: bool = True

    def __post_init__(self) -> None:
        if not self.name:
            raise ConfigError("pack entry has no name")
        if not self.repo_path:
            raise ConfigError(f"pack {self.name!r} has no repo_path")
        if not self.install_as:
            self.install_as = self.name


@dataclass
class Config:
    """Resolved packd configuration."""

    world_dir: Path
    mode: str = DEFAULT_MODE
    host: str = DEFAULT_HOST
    rcon_port: int = DEFAULT_RCON_PORT
    ref: str = "main"
    repo_owner: str = REPO_OWNER
    repo_name: str = REPO_NAME
    packs: list[PackConfig] = field(default_factory=list)
    reload_after_update: bool = True
    state_path: Path | None = None
    source: str = "<defaults>"

    @property
    def datapacks_dir(self) -> Path:
        return self.world_dir / "datapacks"

    @property
    def password(self) -> str:
        """Read the RCON password from the environment, on every access.

        Deliberately a property rather than a stored field: the value is never
        held on the object, so it cannot be pickled, logged by a dataclass
        repr, or written into a state file by accident.
        """
        return os.environ.get(PASSWORD_ENV, "")

    def pack(self, name: str) -> PackConfig:
        for pack in self.packs:
            if pack.name == name or pack.install_as == name:
                return pack
        known = ", ".join(p.name for p in self.packs) or "(none configured)"
        raise ConfigError(f"unknown pack {name!r}. Configured packs: {known}")

    def pack_names(self) -> list[str]:
        return [p.name for p in self.packs]


def _as_bool(value: Any, key: str) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        if value.lower() in ("1", "true", "yes", "on"):
            return True
        if value.lower() in ("0", "false", "no", "off"):
            return False
    raise ConfigError(f"{key} must be a boolean, got {value!r}")


def _as_int(value: Any, key: str) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        raise ConfigError(f"{key} must be an integer, got {value!r}") from None


def _load_raw(path: Path) -> dict[str, Any]:
    """Read a config file. JSON only - no TOML parser is required, so this
    works on the Python 3.9 floor this repo supports (tomllib is 3.11+)."""
    try:
        text = path.read_text(encoding="utf-8")
    except FileNotFoundError:
        raise ConfigError(f"config file not found: {path}") from None
    except OSError as exc:
        raise ConfigError(f"cannot read config file {path}: {exc}") from None
    try:
        data = json.loads(text)
    except json.JSONDecodeError as exc:
        raise ConfigError(f"{path} is not valid JSON: {exc}") from None
    if not isinstance(data, dict):
        raise ConfigError(f"{path} must contain a JSON object at the top level")
    return data


def default_packs() -> list[PackConfig]:
    return [PackConfig(name=n, repo_path=f"packs/{n}") for n in DEFAULT_PACKS]


def load_config(path: Path | None, world_dir: Path | None = None) -> Config:
    """Build a Config from a file, falling back to defaults.

    With no file at all this still returns a usable configuration in
    :data:`DEFAULT_MODE`, so ``packd check`` works before anyone has written
    anything - and works without RCON, since checking is read-only.
    """
    raw: dict[str, Any] = {}
    source = "<defaults>"
    if path is not None:
        raw = _load_raw(path)
        source = str(path)

    resolved_world = world_dir or raw.get("world_dir")
    if resolved_world is None:
        raise ConfigError(
            "no world directory: pass --world or set \"world_dir\" in the config. "
            "It is the folder that contains the world's datapacks/ directory."
        )
    world = Path(str(resolved_world)).expanduser()

    mode = str(raw.get("mode", DEFAULT_MODE)).lower()
    if mode not in VALID_MODES:
        raise ConfigError(
            f"mode must be one of {', '.join(VALID_MODES)}, got {mode!r}"
        )

    host = str(raw.get("host", DEFAULT_HOST))
    if not host:
        raise ConfigError("host must not be empty")

    packs_raw = raw.get("packs")
    if packs_raw is None:
        packs = default_packs()
    elif not isinstance(packs_raw, list) or not packs_raw:
        raise ConfigError('"packs" must be a non-empty list')
    else:
        packs = []
        for entry in packs_raw:
            if isinstance(entry, str):
                packs.append(PackConfig(name=entry, repo_path=f"packs/{entry}"))
            elif isinstance(entry, dict):
                name = str(entry.get("name", ""))
                repo_path = str(entry.get("repo_path", "") or f"packs/{name}")
                packs.append(
                    PackConfig(
                        name=name,
                        repo_path=repo_path,
                        install_as=str(entry.get("install_as", "")),
                        enabled=_as_bool(entry.get("enabled", True), "packs[].enabled"),
                    )
                )
            else:
                raise ConfigError(f'"packs" entries must be strings or objects, got {entry!r}')

    state_path = raw.get("state_file")
    cfg = Config(
        world_dir=world,
        mode=mode,
        host=host,
        rcon_port=_as_int(raw.get("rcon_port", DEFAULT_RCON_PORT), "rcon_port"),
        ref=str(raw.get("ref", "main")),
        repo_owner=str(raw.get("repo_owner", REPO_OWNER)),
        repo_name=str(raw.get("repo_name", REPO_NAME)),
        packs=packs,
        reload_after_update=_as_bool(
            raw.get("reload_after_update", True), "reload_after_update"
        ),
        state_path=Path(str(state_path)).expanduser() if state_path else None,
        source=source,
    )
    if not (1 <= cfg.rcon_port <= 65535):
        raise ConfigError(f"rcon_port out of range: {cfg.rcon_port}")
    return cfg


def config_template(world_dir: str = "/path/to/world") -> str:
    """The file ``packd init`` writes."""
    return json.dumps(
        {
            "world_dir": world_dir,
            "mode": DEFAULT_MODE,
            "host": DEFAULT_HOST,
            "rcon_port": DEFAULT_RCON_PORT,
            "ref": "main",
            "reload_after_update": True,
            "packs": [
                {"name": n, "repo_path": f"packs/{n}"} for n in DEFAULT_PACKS
            ],
            "_comment": [
                "mode: 'check' reports only (default), 'approve' applies after a yes,",
                "'auto' applies without asking.",
                f"The RCON password is NOT set here. Export {PASSWORD_ENV} instead;",
                "SECURITY.md section 4 forbids committing it.",
            ],
        },
        indent=2,
    ) + "\n"
