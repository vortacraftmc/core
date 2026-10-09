"""Mode gating: what each mode is allowed to do.

This is the file to read if you want to know whether packd can change a server
without being asked. The answer has to be: only in ``auto``, or in ``approve``
after a yes - and never in the default ``check`` mode.
"""

from __future__ import annotations

from pathlib import Path

import pytest

from packd.config import MODE_APPROVE, MODE_AUTO, MODE_CHECK, Config, ConfigError, PackConfig
from packd.github import Commit, GitHubError, Issue
from packd.installer import Installer
from packd.rcon import RconClient
from packd.state import State
from packd.updater import Updater


class FakeGitHub:
    """Stands in for the API so tests never touch the network."""

    def __init__(self, latest: str = "b" * 40, behind: list[Commit] | None = None):
        self.latest_sha = latest
        self.behind = behind if behind is not None else []
        self.downloads: list[tuple[str, str]] = []
        self.fail_commit = False

    def latest_commit(self, path: str, ref: str = "main") -> Commit:
        if self.fail_commit:
            raise GitHubError("simulated API failure")
        return Commit(
            sha=self.latest_sha,
            message="upstream change",
            date="2026-01-01T00:00:00Z",
            author="someone",
            url="https://example.invalid",
        )

    def commit(self, sha: str) -> Commit:
        return Commit(sha=sha, message="m", date="", author="", url="")

    def commits_between(self, path, old, new, limit=50):
        return self.behind[:limit]

    def download_tree(self, sha: str, subdir: str) -> dict[str, bytes]:
        self.downloads.append((sha, subdir))
        return {
            "pack.mcmeta": b'{"pack":{"min_format":[122,0],"max_format":[122,0]}}',
            "data/demo/function/load.mcfunction": f"# {sha[:7]}\n".encode(),
        }

    def open_issues(self, limit: int = 20, labels=()) -> list[Issue]:
        return [
            Issue(
                number=1,
                title="An issue",
                state="open",
                author="someone",
                created="",
                updated="",
                url="https://example.invalid/1",
                labels=(),
                body="body",
            )
        ]


class FakeClient(RconClient):
    """An RconClient that records instead of connecting."""

    def __init__(self) -> None:
        super().__init__("127.0.0.1", 1, "x")
        self.sent: list[str] = []

    def connect(self) -> None:
        """A no-op, so `with client:` works. Asserting here instead would break
        every `with` block; socket use is covered by test_rcon."""

    def command(self, command: str) -> str:
        self.policy.check(command)
        self.sent.append(command)
        return ""

    def close(self) -> None:
        pass


def make(tmp_path: Path, mode: str, installed_sha: str = "") -> tuple[Updater, FakeGitHub, FakeClient, State]:
    world = tmp_path / "world"
    (world / "datapacks").mkdir(parents=True)
    config = Config(
        world_dir=world,
        mode=mode,
        packs=[PackConfig(name="demo", repo_path="packs/demo", install_as="demo")],
    )
    github = FakeGitHub()
    state = State(path=world / "datapacks" / ".packd-state.json")
    if installed_sha:
        state.record("demo", installed_sha, source="adopt")
    client = FakeClient()
    updater = Updater(
        config,
        github,
        Installer(world / "datapacks"),
        state,
        confirm=lambda _p: True,
        log=lambda _m: None,
    )
    return updater, github, client, state


# ------------------------------------------------------------------- decide


@pytest.mark.parametrize(
    "mode,expected",
    [(MODE_CHECK, "skip"), (MODE_APPROVE, "ask"), (MODE_AUTO, "apply")],
)
def test_mode_maps_to_exactly_one_action(tmp_path, mode, expected):
    updater, _, _, _ = make(tmp_path, mode)
    assert updater.decide("demo").action == expected


def test_default_mode_is_check(tmp_path):
    from packd.config import DEFAULT_MODE

    assert DEFAULT_MODE == MODE_CHECK
    updater, _, _, _ = make(tmp_path, DEFAULT_MODE)
    assert updater.decide("demo").action == "skip"


# -------------------------------------------------- check mode changes nothing


def test_check_mode_writes_no_files_and_sends_no_commands(tmp_path):
    updater, github, client, state = make(tmp_path, MODE_CHECK)
    changed = updater.run(client_factory=lambda: client)

    assert changed == 0
    assert github.downloads == [], "check must not download anything"
    assert client.sent == [], "check must not touch the server"
    assert not (tmp_path / "world/datapacks/demo").exists()


def test_check_mode_needs_no_rcon_at_all(tmp_path):
    """No client factory is even passed - the mode must not ask for one."""
    updater, _, _, _ = make(tmp_path, MODE_CHECK)
    assert updater.run(client_factory=None) == 0


def test_check_mode_does_not_record_state(tmp_path):
    updater, _, _, state = make(tmp_path, MODE_CHECK)
    updater.run(client_factory=None)
    assert state.get("demo").sha == ""


# ------------------------------------------------------------- approve mode


def test_approve_mode_applies_after_a_yes(tmp_path):
    updater, github, client, state = make(tmp_path, MODE_APPROVE)
    changed = updater.run(client_factory=lambda: client)

    assert changed == 1
    assert github.downloads, "approve+yes must download"
    assert "reload" in client.sent
    assert state.get("demo").sha == "b" * 40


def test_approve_mode_does_nothing_after_a_no(tmp_path):
    updater, github, client, state = make(tmp_path, MODE_APPROVE)
    updater.confirm = lambda _p: False
    changed = updater.run(client_factory=lambda: client)

    assert changed == 0
    assert github.downloads == []
    assert client.sent == []


def test_approve_mode_does_not_apply_when_confirm_is_unanswered(tmp_path):
    """A closed stdin must mean no, never yes."""
    from packd.updater import _default_confirm

    import builtins

    original = builtins.input
    builtins.input = lambda _p="": (_ for _ in ()).throw(EOFError())
    try:
        assert _default_confirm("apply?") is False
    finally:
        builtins.input = original


# ---------------------------------------------------------------- auto mode


def test_auto_mode_applies_without_asking(tmp_path):
    asked: list[str] = []

    def confirm(prompt: str) -> bool:
        asked.append(prompt)
        return False  # would block if it were consulted

    updater, github, client, _ = make(tmp_path, MODE_AUTO)
    updater.confirm = confirm
    changed = updater.run(client_factory=lambda: client)

    assert changed == 1
    assert asked == [], "auto must not prompt"


# -------------------------------------------------------------------- apply


def test_up_to_date_pack_is_left_alone(tmp_path):
    updater, github, client, _ = make(tmp_path, MODE_AUTO, installed_sha="b" * 40)
    assert updater.run(client_factory=lambda: client) == 0
    assert github.downloads == []


def test_reload_is_skipped_when_disabled(tmp_path):
    updater, _, client, _ = make(tmp_path, MODE_AUTO)
    updater.config.reload_after_update = False
    updater.run(client_factory=lambda: client)
    assert client.sent == []


def test_apply_records_the_revision_in_state(tmp_path):
    updater, _, _, state = make(tmp_path, MODE_AUTO)
    updater.run(client_factory=lambda: client_for(updater))
    assert state.get("demo").sha == "b" * 40
    assert state.path.exists(), "state must be persisted"


def client_for(_updater) -> FakeClient:
    return FakeClient()


def test_a_pack_specific_api_failure_is_reported_not_raised(tmp_path):
    updater, github, client, _ = make(tmp_path, MODE_CHECK)
    github.fail_commit = True
    statuses = updater.status()
    assert statuses[0].error, "the failure must be captured per pack"
    assert updater.run(client_factory=lambda: client) == 0


# ----------------------------------------------------------------- rollback


def test_rollback_uses_the_local_backup_first(tmp_path):
    updater, github, client, state = make(tmp_path, MODE_AUTO, installed_sha="a" * 40)
    updater.installer.install("demo", "a" * 40, github.download_tree("a" * 40, "packs/demo"))
    updater.apply("demo", "b" * 40)
    github.downloads.clear()

    result = updater.rollback("demo", "a" * 40)
    assert result.restored_from_backup is True
    assert github.downloads == [], "a stored revision must not be re-downloaded"
    assert state.get("demo").sha == "a" * 40


def test_use_an_arbitrary_sha_fetches_it(tmp_path):
    updater, github, client, state = make(tmp_path, MODE_AUTO)
    result = updater.apply("demo", "c" * 40)
    assert result.sha == "c" * 40
    assert github.downloads == [("c" * 40, "packs/demo")]
    assert state.get("demo").sha == "c" * 40


def test_history_lists_previous_revisions(tmp_path):
    updater, github, _, state = make(tmp_path, MODE_AUTO)
    updater.apply("demo", "a" * 40)
    updater.apply("demo", "b" * 40)
    assert state.previous_shas("demo") == ["a" * 40]


def test_unknown_pack_is_a_config_error(tmp_path):
    updater, _, _, _ = make(tmp_path, MODE_CHECK)
    with pytest.raises(ConfigError):
        updater.apply("nope")
