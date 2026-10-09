"""Command line interface.

Subcommands, in the order a new user needs them::

    packd init                 write a starter config
    packd status               what is installed, from local state
    packd check                what is newer upstream (read-only, no RCON)
    packd update               apply, honouring the configured mode
    packd use <sha>            install a specific revision, old or new
    packd rollback [<sha>]     go back to a revision you have been on
    packd history              revisions this tool has installed
    packd issues               publish open GitHub issues into the game
    packd test-connection      prove RCON works before you need it

``check`` and ``status`` never open a connection to the server. The password is
read from :data:`packd.config.PASSWORD_ENV` and is never echoed back - not in
output, not in an error message, not in the state file.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Sequence

from . import __version__
from .config import (
    DEFAULT_HOST,
    DEFAULT_RCON_PORT,
    MODE_APPROVE,
    MODE_AUTO,
    MODE_CHECK,
    PASSWORD_ENV,
    VALID_MODES,
    Config,
    ConfigError,
    config_template,
    load_config,
)
from .github import GitHub, GitHubError
from .installer import InstallError, Installer
from .issues import STORAGE_ID, build_issues_commands, clear_command, refresh_command
from .rcon import CommandPolicy, RconAuthError, RconClient, RconError, RconPolicyError
from .state import State, StateError, default_state_path
from .updater import UpdateError, Updater
from .verify import TriState, summarise

EXIT_OK = 0
EXIT_GENERIC = 1
EXIT_USAGE = 2
EXIT_UPDATE_AVAILABLE = 3
EXIT_SERVER = 4


class _Formatter(argparse.RawDescriptionHelpFormatter):
    pass


def _die(message: str, code: int = EXIT_GENERIC) -> int:
    print(f"packd: {message}", file=sys.stderr)
    return code


def _client_for(config: Config) -> RconClient:
    """Build (but do not connect) an RCON client.

    The password comes from the environment. Refusing to start when it is empty
    is what makes "RCON disabled by default" true in practice rather than in
    documentation.
    """
    password = config.password
    if not password:
        raise RconError(
            f"no RCON password: export {PASSWORD_ENV}. SECURITY.md section 4 "
            f"requires it to come from the environment or a secret store, so "
            f"packd will not read it from the config file."
        )
    return RconClient(
        config.host, config.rcon_port, password, policy=CommandPolicy()
    )


def _connect(config: Config) -> RconClient:
    client = _client_for(config)
    client.connect()
    return client


def _github_for(config: Config) -> GitHub:
    return GitHub(config.repo_owner, config.repo_name)


def _state_for(config: Config) -> State:
    path = config.state_path or default_state_path(config.world_dir)
    return State.load(path)


# ---------------------------------------------------------------- commands


def cmd_init(args: argparse.Namespace) -> int:
    path = Path(args.config) if args.config else Path("packd.json")
    if path.exists() and not args.force:
        return _die(f"{path} already exists (use --force to overwrite)", EXIT_USAGE)
    path.write_text(config_template(args.world or "/path/to/world"), encoding="utf-8")
    print(f"wrote {path}")
    print("  set your world directory, then set the RCON password environment variable to use the server commands")
    return EXIT_OK


def cmd_status(args: argparse.Namespace) -> int:
    config = _load(args)
    if config is None:
        return EXIT_USAGE
    state = _state_for(config)
    installer = Installer(config.datapacks_dir)
    print(f"config:   {config.source}")
    print(f"world:    {config.world_dir}")
    print(f"mode:     {config.mode}")
    print(f"rcon:     {config.host}:{config.rcon_port} "
          f"({'password set' if config.password else 'no password set'})")
    print()
    for pack in config.packs:
        entry = state.packs.get(pack.name)
        present = installer.detect_installed(pack.install_as)
        marker = "+" if present else "-"
        sha = entry.short_sha if entry else "-"
        when = entry.installed_at if entry else ""
        print(f"  {marker} {pack.name:<32} {sha:<10} {when}")
        if not present:
            print(f"      not present in {config.datapacks_dir}")
    return EXIT_OK


def cmd_check(args: argparse.Namespace) -> int:
    config = _load(args)
    if config is None:
        return EXIT_USAGE
    updater = Updater(
        config,
        _github_for(config),
        Installer(config.datapacks_dir),
        _state_for(config),
        log=print,
    )
    try:
        statuses = updater.status(args.pack or None)
    except GitHubError as exc:
        return _die(str(exc))
    from .report import describe_all

    outdated = describe_all(statuses)
    print()
    if outdated:
        print(f"{outdated} pack(s) have an update available. Nothing was changed.")
        print(f"run `packd update --mode {MODE_APPROVE}` to apply interactively.")
        return EXIT_UPDATE_AVAILABLE
    print("everything is up to date.")
    return EXIT_OK


def cmd_update(args: argparse.Namespace) -> int:
    config = _load(args)
    if config is None:
        return EXIT_USAGE
    mode = args.mode or config.mode
    if mode not in VALID_MODES:
        return _die(f"--mode must be one of {', '.join(VALID_MODES)}", EXIT_USAGE)
    if mode == MODE_AUTO and not args.yes_i_mean_auto:
        print(
            "note: --mode auto applies updates without asking. Pass "
            "--yes-i-mean-auto to confirm you want that.",
            file=sys.stderr,
        )
        return EXIT_USAGE
    confirm = None
    if args.yes:
        confirm = lambda _prompt: True  # noqa: E731 - explicit override
    if args.no:
        confirm = lambda _prompt: False  # noqa: E731
    updater = Updater(
        config,
        _github_for(config),
        Installer(config.datapacks_dir),
        _state_for(config),
        confirm=confirm,
        log=print,
    )
    try:
        changed = updater.run(
            args.pack or None,
            requested_mode=mode,
            client_factory=(lambda: _connect(config)) if not args.no_reload else None,
            use_server=not args.no_reload,
        )
    except (UpdateError, GitHubError, ConfigError) as exc:
        return _die(str(exc))
    except RconError as exc:
        return _die(str(exc), EXIT_SERVER)
    print()
    print(f"{changed} pack(s) updated." if changed else "nothing changed.")
    return EXIT_OK


def cmd_use(args: argparse.Namespace) -> int:
    """Install a specific revision - older or newer than what is installed."""
    config = _load(args)
    if config is None:
        return EXIT_USAGE
    name = _require_pack(config, args.pack)
    if name is None:
        return EXIT_USAGE
    installer = Installer(config.datapacks_dir)
    updater = Updater(config, _github_for(config), installer, _state_for(config), log=print)
    try:
        result = updater.apply(name, args.sha)
    except (InstallError, GitHubError, ConfigError) as exc:
        return _die(str(exc))
    print(f"installed {result.sha[:12]} -> {result.target} ({result.files} files)")
    return _maybe_reload(config, args, [config.pack(name).install_as])


def cmd_rollback(args: argparse.Namespace) -> int:
    config = _load(args)
    if config is None:
        return EXIT_USAGE
    name = _require_pack(config, args.pack)
    if name is None:
        return EXIT_USAGE
    state = _state_for(config)
    installer = Installer(config.datapacks_dir)
    updater = Updater(config, _github_for(config), installer, state, log=print)

    sha = args.sha
    if not sha:
        previous = state.previous_shas(name)
        stored = installer.list_backups(config.pack(name).install_as)
        candidates = previous or stored
        if not candidates:
            return _die(
                f"no previous revision recorded for {name}. Pass an explicit sha, "
                f"or use `packd use <sha>`."
            )
        sha = candidates[0]
        print(f"rolling {name} back to {sha[:12]} (most recent previous revision)")
    try:
        result = updater.rollback(name, sha)
    except (InstallError, GitHubError, ConfigError) as exc:
        return _die(str(exc))
    origin = "local backup" if result.restored_from_backup else "GitHub"
    print(f"restored {result.sha[:12]} from {origin} ({result.files} files)")
    return _maybe_reload(config, args, [config.pack(name).install_as])


def cmd_history(args: argparse.Namespace) -> int:
    config = _load(args)
    if config is None:
        return EXIT_USAGE
    name = _require_pack(config, args.pack)
    if name is None:
        return EXIT_USAGE
    state = _state_for(config)
    installer = Installer(config.datapacks_dir)
    pack_state = state.packs.get(name)
    install_as = config.pack(name).install_as
    print(f"{name}")
    if pack_state and pack_state.known:
        print(f"  current   {pack_state.short_sha}  {pack_state.installed_at}  ref={pack_state.ref}")
    for entry in (pack_state.history if pack_state else []):
        print(f"  previous  {entry.sha[:7]}  {entry.installed_at}  {entry.source}")
    stored = installer.list_backups(install_as)
    if stored:
        print(f"  offline   {', '.join(s[:7] for s in stored)}  (restorable without network)")
    if not (pack_state and pack_state.known) and not stored:
        print("  nothing recorded yet - run `packd check` first")
    return EXIT_OK


def cmd_issues(args: argparse.Namespace) -> int:
    """Fetch open issues and publish them where the datapack can show them."""
    config = _load(args)
    if config is None:
        return EXIT_USAGE
    github = _github_for(config)
    try:
        issues = github.open_issues(limit=args.limit, labels=args.label or ())
    except GitHubError as exc:
        return _die(str(exc))

    if args.list:
        if not issues:
            print("no open issues")
            return EXIT_OK
        for issue in issues:
            labels = f" [{', '.join(issue.labels[:3])}]" if issue.labels else ""
            print(f"  #{issue.number:<5} {issue.title[:70]}{labels}")
            print(f"         {issue.url}")
        return EXIT_OK

    from datetime import datetime, timezone

    payload = build_issues_commands(
        issues,
        fetched_at=datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        storage_id=args.storage,
    )
    if payload.truncated:
        print(
            f"note: {payload.included}/{payload.total} issue(s) included"
            f"{'' if payload.with_body else ', body previews dropped'} to fit "
            f"the {payload.commands[0].__len__()} byte command limit",
            file=sys.stderr,
        )
    try:
        with _connect(config) as client:
            client.command(clear_command(args.storage))
            for command in payload.commands:
                client.command(command)
            client.command(refresh_command(args.namespace))
    except RconError as exc:
        return _die(str(exc), EXIT_SERVER)
    print(
        f"published {payload.included} issue(s) to {args.storage}. "
        f"Run /function {args.namespace}:issues in game."
    )
    return EXIT_OK


def cmd_test_connection(args: argparse.Namespace) -> int:
    config = _load(args)
    if config is None:
        return EXIT_USAGE
    print(f"connecting to {RconClient.safe_repr(config.host, config.rcon_port)} ...")
    try:
        with _connect(config) as client:
            reply = client.command("datapack list")
    except RconAuthError:
        return _die(
            "authentication failed - wrong password, or rcon is disabled on the "
            "server (enable-rcon=false is the documented default)",
            EXIT_SERVER,
        )
    except RconError as exc:
        return _die(str(exc), EXIT_SERVER)
    print("authenticated.")
    print(f"  datapack list -> {summarise(reply)}")
    return EXIT_OK


# ------------------------------------------------------------------ helpers


def _load(args: argparse.Namespace) -> Config | None:
    try:
        config = load_config(
            Path(args.config) if args.config else None,
            Path(args.world) if args.world else None,
        )
    except ConfigError as exc:
        _die(str(exc), EXIT_USAGE)
        return None
    try:
        state = _state_for(config)  # noqa: F841 - validates early
    except StateError as exc:
        _die(str(exc))
        return None
    return config


def _require_pack(config: Config, requested: str | None) -> str | None:
    if requested:
        try:
            return config.pack(requested).name
        except ConfigError as exc:
            _die(str(exc), EXIT_USAGE)
            return None
    names = config.pack_names()
    if len(names) == 1:
        return names[0]
    _die(
        f"--pack is required; configured packs: {', '.join(names)}", EXIT_USAGE
    )
    return None


def _maybe_reload(
    config: Config, args: argparse.Namespace, install_as: Sequence[str]
) -> int:
    if args.no_reload or not config.reload_after_update:
        print("files written; the server was not reloaded (run /reload yourself)")
        return EXIT_OK
    try:
        with _connect(config) as client:
            for name in install_as:
                client.command(f"datapack enable file/{name}")
            reply = client.command("reload")
    except RconError as exc:
        print(
            f"files written, but the server was not reloaded: {exc}",
            file=sys.stderr,
        )
        return EXIT_OK
    from .verify import reload_ok

    state = reload_ok(reply)
    if state is TriState.NO:
        print(f"reload reported a problem: {summarise(reply)}", file=sys.stderr)
    else:
        print("reloaded.")
    return EXIT_OK


# ------------------------------------------------------------------- parser


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="packd",
        description=(
            "Check, update and roll back the datapacks in a Minecraft world, "
            "without deleting and reinstalling them by hand."
        ),
        epilog=(
            "Modes: 'check' reports only (the default and the only mode that "
            "needs no RCON), 'approve' applies after you answer yes, 'auto' "
            f"applies without asking.\n\nThe RCON password comes from the "
            f"{PASSWORD_ENV} environment variable only."
        ),
        formatter_class=_Formatter,
    )
    parser.add_argument("-v", "--version", action="version", version=f"packd {__version__}")
    parser.add_argument("-c", "--config", help="config file (default: ./packd.json)")
    parser.add_argument("-w", "--world", help="world directory (overrides the config)")

    sub = parser.add_subparsers(dest="command", metavar="COMMAND")

    p = sub.add_parser("init", help="write a starter config file")
    p.add_argument("--force", action="store_true", help="overwrite an existing file")
    # Also on the top-level parser, but repeated here so the natural spelling
    # `packd init --world DIR` works and not only `packd --world DIR init`.
    p.add_argument("-w", "--world", dest="world", help="world directory to write into the config")
    p.set_defaults(func=cmd_init)

    p = sub.add_parser("status", help="show what is installed, from local state")
    p.set_defaults(func=cmd_status)

    p = sub.add_parser("check", help="report available updates (read-only, no RCON)")
    p.add_argument("--pack", action="append", help="limit to a pack (repeatable)")
    p.set_defaults(func=cmd_check)

    p = sub.add_parser("update", help="apply updates according to the mode")
    p.add_argument("--pack", action="append", help="limit to a pack (repeatable)")
    p.add_argument("--mode", choices=VALID_MODES, help="override the configured mode")
    p.add_argument("-y", "--yes", action="store_true", help="answer yes to every prompt")
    p.add_argument("-n", "--no", action="store_true", help="answer no to every prompt")
    p.add_argument("--no-reload", action="store_true", help="write files but do not touch the server")
    p.add_argument(
        "--yes-i-mean-auto",
        action="store_true",
        help="required alongside --mode auto, so autonomy is never accidental",
    )
    p.set_defaults(func=cmd_update)

    p = sub.add_parser("use", help="install a specific revision, older or newer")
    p.add_argument("sha", help="commit sha, tag or branch")
    p.add_argument("--pack", help="pack to install")
    p.add_argument("--no-reload", action="store_true")
    p.set_defaults(func=cmd_use)

    p = sub.add_parser("rollback", help="return to a revision you have been on")
    p.add_argument("sha", nargs="?", help="revision (default: the previous one)")
    p.add_argument("--pack", help="pack to roll back")
    p.add_argument("--no-reload", action="store_true")
    p.set_defaults(func=cmd_rollback)

    p = sub.add_parser("history", help="revisions this tool has installed")
    p.add_argument("--pack", help="pack to inspect")
    p.set_defaults(func=cmd_history)

    p = sub.add_parser("issues", help="publish open GitHub issues into the game")
    p.add_argument("--limit", type=int, default=15, help="how many issues (default 15)")
    p.add_argument("--label", action="append", help="only issues with this label (repeatable)")
    p.add_argument("--list", action="store_true", help="print them here instead of publishing")
    p.add_argument("--storage", default=STORAGE_ID, help=f"storage id (default {STORAGE_ID})")
    p.add_argument(
        "--namespace",
        default="macroengine",
        choices=("macroengine", "guikit"),
        help="which pack renders them",
    )
    p.set_defaults(func=cmd_issues)

    p = sub.add_parser("test-connection", help="check that RCON works")
    p.set_defaults(func=cmd_test_connection)

    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if not getattr(args, "command", None):
        parser.print_help()
        return EXIT_USAGE
    try:
        return int(args.func(args))
    except KeyboardInterrupt:
        return _die("interrupted", EXIT_GENERIC)
    except RconPolicyError as exc:
        return _die(f"refused by the command allowlist: {exc}", EXIT_GENERIC)


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
