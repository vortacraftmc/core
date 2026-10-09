"""Deciding whether an available update gets applied.

The three modes, and what each one is allowed to do:

==========  ==========  ==========  =============================
mode        network     files       server
==========  ==========  ==========  =============================
``check``   read-only   none        none - no RCON connection made
``approve`` read-only   after yes   after yes
``auto``    read-only   yes         yes
==========  ==========  ==========  =============================

``check`` is the default (see :data:`packd.config.DEFAULT_MODE`) and is the
only mode that works with no RCON configured at all, which is what SECURITY.md
section 4 means by RCON being disabled by default.

The autonomy decision is made in exactly one place, :meth:`Updater.decide`, so
there is a single line to audit for "can this change my server without me
asking". The answer is: only in ``auto``, or in ``approve`` after
:meth:`Updater.confirm` returns true.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Callable, Sequence

from .config import (
    MODE_APPROVE,
    MODE_AUTO,
    MODE_CHECK,
    PASSWORD_ENV,
    Config,
    PackConfig,
)
from .github import Commit, GitHub, GitHubError
from .installer import InstallError, InstallResult, Installer
from .rcon import RconClient, RconError
from .state import State
from .verify import TriState, datapack_state, reload_ok, summarise


class UpdateError(Exception):
    """An update could not be planned or applied."""


@dataclass
class PackStatus:
    """What is known about one pack, before deciding anything."""

    pack: PackConfig
    installed_sha: str = ""
    latest_sha: str = ""
    latest: Commit | None = None
    behind: list[Commit] = field(default_factory=list)
    installed: bool = False
    error: str = ""

    @property
    def up_to_date(self) -> bool:
        return bool(self.installed_sha) and self.installed_sha == self.latest_sha

    @property
    def update_available(self) -> bool:
        return not self.error and bool(self.latest_sha) and self.installed_sha != self.latest_sha

    @property
    def behind_count(self) -> int:
        return len(self.behind)


@dataclass
class Decision:
    """The outcome of the autonomy check for one pack."""

    pack: str
    action: str  # "skip", "apply", "ask"
    reason: str


def _now() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


class Updater:
    """Plans updates, asks when it must, and applies when allowed."""

    def __init__(
        self,
        config: Config,
        github: GitHub,
        installer: Installer,
        state: State,
        *,
        confirm: Callable[[str], bool] | None = None,
        log: Callable[[str], None] = print,
    ) -> None:
        self.config = config
        self.github = github
        self.installer = installer
        self.state = state
        # Injectable so tests never have to answer a prompt, and so the default
        # (no terminal) cannot silently become a "yes".
        self.confirm = confirm or _default_confirm
        self.log = log

    # --------------------------------------------------------------- decide

    def decide(self, pack: str, *, requested_mode: str | None = None) -> Decision:
        """The single place that turns mode into action.

        Anything other than ``auto`` never applies without an explicit
        confirmation. ``check`` never applies at all, even if confirmed,
        because the user asked to be told rather than changed.
        """
        mode = (requested_mode or self.config.mode).lower()
        if mode == MODE_AUTO:
            return Decision(pack, "apply", "mode is 'auto'")
        if mode == MODE_APPROVE:
            return Decision(pack, "ask", "mode is 'approve'")
        return Decision(pack, "skip", "mode is 'check' (report only)")

    # --------------------------------------------------------------- status

    def status(self, names: Sequence[str] | None = None) -> list[PackStatus]:
        """Read-only survey. Makes no connection to the server."""
        wanted = list(names) if names else self.config.pack_names()
        out: list[PackStatus] = []
        for name in wanted:
            try:
                pack = self.config.pack(name)
            except Exception as exc:  # noqa: BLE001 - reported per pack
                out.append(PackStatus(pack=PackConfig(name=name, repo_path=""), error=str(exc)))
                continue
            entry = PackStatus(pack=pack)
            entry.installed = self.installer.detect_installed(pack.install_as)
            entry.installed_sha = self.state.get(pack.name).sha
            try:
                entry.latest = self.github.latest_commit(pack.repo_path, ref=self.config.ref)
                entry.latest_sha = entry.latest.sha
            except GitHubError as exc:
                entry.error = str(exc)
                out.append(entry)
                continue
            if entry.installed_sha and entry.installed_sha != entry.latest_sha:
                try:
                    entry.behind = self.github.commits_between(
                        pack.repo_path, entry.installed_sha, entry.latest_sha, limit=10
                    )
                except GitHubError:
                    entry.behind = []
            out.append(entry)
        return out

    # ---------------------------------------------------------------- apply

    def apply(self, pack_name: str, sha: str | None = None) -> InstallResult:
        """Install `sha` (default: newest on the configured ref) for one pack."""
        pack = self.config.pack(pack_name)
        target_sha = sha
        if not target_sha:
            target_sha = self.github.latest_commit(
                pack.repo_path, ref=self.config.ref
            ).sha
        previous = self.state.get(pack.name).sha
        result = self.installer.fetch_and_install(
            self.github, pack.install_as, pack.repo_path, target_sha,
            previous_sha=previous,
        )
        self.state.record(
            pack.name, target_sha, source="update", ref=self.config.ref
        )
        self.state.save()
        return result

    def rollback(self, pack_name: str, sha: str) -> InstallResult:
        """Restore a revision, preferring the local backup over the network."""
        pack = self.config.pack(pack_name)
        stored = self.installer.existing_backup(pack.install_as, sha)
        if stored is not None:
            result = self.installer.rollback(pack.install_as, sha)
        else:
            result = self.installer.fetch_and_install(
                self.github, pack.install_as, pack.repo_path, sha,
                previous_sha=self.state.get(pack.name).sha,
            )
        self.state.record(pack.name, result.sha, source="rollback", ref=self.config.ref)
        self.state.save()
        return result

    # --------------------------------------------------------------- server

    def reload(self, client: RconClient) -> tuple[TriState, str]:
        """Send ``/reload`` and report what the server said."""
        reply = client.command("reload")
        return reload_ok(reply), summarise(reply)

    def ensure_enabled(self, client: RconClient, install_as: str, enabled: bool) -> str:
        verb = "enable" if enabled else "disable"
        return client.command(f"datapack {verb} file/{install_as}")

    def confirm_pack_loaded(self, client: RconClient, install_as: str) -> TriState:
        reply = client.command("datapack list")
        return datapack_state(reply, install_as)

    # ----------------------------------------------------------------- run

    def run(
        self,
        names: Sequence[str] | None = None,
        *,
        requested_mode: str | None = None,
        client_factory: Callable[[], RconClient] | None = None,
        use_server: bool = True,
    ) -> int:
        """Check, then apply only what the mode permits.

        Returns the number of packs that were changed, so the CLI can exit
        non-zero on failure and scripts can tell "nothing to do" from "updated".
        """
        statuses = self.status(names)
        changed = 0
        needs_server = False
        plan: list[tuple[PackStatus, Decision]] = []

        from .report import describe

        for entry in statuses:
            # One reporter shared with `packd check`, so the two commands
            # describe a pack identically instead of one of them drifting into
            # printing less than the other.
            describe(entry, self.log)
            if entry.error:
                continue
            decision = self.decide(entry.pack.name, requested_mode=requested_mode)
            if not entry.update_available:
                continue
            if decision.action == "skip":
                self.log(f"      not applied - {decision.reason}. Use --mode approve or --mode auto.")
                continue
            if decision.action == "ask":
                if not self.confirm(f"Apply {entry.latest_sha[:7]} to {entry.pack.name}?"):
                    self.log("      declined")
                    continue
            plan.append((entry, decision))
            needs_server = True

        if not plan:
            return 0

        # `use_server=False` is an explicit "write the files and stop", which
        # is different from "I wanted a connection and do not have one".
        # Overloading client_factory=None for both made --no-reload fail with a
        # missing-password error instead of doing the thing it was asked to do.
        client: RconClient | None = None
        if needs_server and use_server and self.config.reload_after_update:
            if client_factory is None:
                raise UpdateError(
                    "an update was approved but no RCON connection is available; "
                    f"export {PASSWORD_ENV} "
                    "and make sure rcon is enabled on the server, or set "
                    "\"reload_after_update\": false to write files only"
                )
            client = client_factory()

        try:
            for entry, _decision in plan:
                try:
                    result = self.apply(entry.pack.name, entry.latest_sha)
                except (InstallError, GitHubError) as exc:
                    self.log(f"  x {entry.pack.name}: {exc}")
                    continue
                self.log(
                    f"  + {entry.pack.name}: installed {result.sha[:7]} "
                    f"({result.files} files, {result.bytes} bytes)"
                )
                changed += 1
                if client is not None:
                    try:
                        if entry.pack.enabled:
                            self.ensure_enabled(client, entry.pack.install_as, True)
                        state, detail = self.reload(client)
                        if state is TriState.NO:
                            self.log(f"  ! reload reported a problem: {detail}")
                        else:
                            loaded = self.confirm_pack_loaded(client, entry.pack.install_as)
                            if loaded is TriState.NO:
                                self.log(
                                    f"  ! {entry.pack.install_as} does not appear in "
                                    f"`datapack list` after reload"
                                )
                            else:
                                self.log(f"  + reloaded ({loaded.value})")
                    except RconError as exc:
                        self.log(f"  ! files updated but the server was not reloaded: {exc}")
        finally:
            if client is not None:
                client.close()

        return changed


def _default_confirm(prompt: str) -> bool:
    """Ask on stdin. Anything other than an explicit yes is a no.

    A closed or non-interactive stdin therefore means "do nothing", which is
    the safe answer: a cron job must never apply an update by accident.
    """
    try:
        answer = input(f"{prompt} [y/N] ")
    except (EOFError, KeyboardInterrupt):
        return False
    return answer.strip().lower() in ("y", "yes")
