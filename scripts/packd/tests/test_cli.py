"""End-to-end CLI tests: real argv in, exit codes and side effects out.

GitHub is replaced with the in-test fake and RCON with the fake server, so
these exercise the wiring between the modules - which is where the mode
guarantees actually have to hold.
"""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from packd import cli
from packd.config import PASSWORD_ENV
from packd.github import Commit

from .test_updater import FakeClient, FakeGitHub


@pytest.fixture
def world(tmp_path: Path, monkeypatch) -> Path:
    path = tmp_path / "world"
    (path / "datapacks").mkdir(parents=True)
    config = {
        "world_dir": str(path),
        "mode": "check",
        "packs": [{"name": "demo", "repo_path": "packs/demo"}],
    }
    (tmp_path / "packd.json").write_text(json.dumps(config), encoding="utf-8")
    monkeypatch.delenv(PASSWORD_ENV, raising=False)
    return path


@pytest.fixture
def fake_github(monkeypatch):
    github = FakeGitHub()
    monkeypatch.setattr(cli, "_github_for", lambda _config: github)
    return github


@pytest.fixture
def fake_client(monkeypatch):
    client = FakeClient()
    monkeypatch.setattr(cli, "_connect", lambda _config: client)
    return client


def run(argv: list[str], tmp_path: Path) -> int:
    return cli.main(["--config", str(tmp_path / "packd.json")] + argv)


# ------------------------------------------------------------------- basics


def test_no_command_prints_help_and_exits_2(tmp_path, world):
    assert cli.main([]) == cli.EXIT_USAGE


def test_version(capsys):
    with pytest.raises(SystemExit) as exc:
        cli.main(["--version"])
    assert exc.value.code == 0
    assert "packd" in capsys.readouterr().out


def test_init_writes_a_usable_config(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    assert cli.main(["init", "--world", str(tmp_path / "w")]) == cli.EXIT_OK
    written = json.loads((tmp_path / "packd.json").read_text(encoding="utf-8"))
    assert written["mode"] == "check"
    assert "password" not in written


def test_init_refuses_to_clobber_without_force(tmp_path, monkeypatch):
    monkeypatch.chdir(tmp_path)
    (tmp_path / "packd.json").write_text("{}", encoding="utf-8")
    assert cli.main(["init"]) == cli.EXIT_USAGE
    assert cli.main(["init", "--force", "--world", str(tmp_path)]) == cli.EXIT_OK


def test_missing_config_is_a_usage_error(tmp_path):
    assert cli.main(["--config", str(tmp_path / "nope.json"), "status"]) == cli.EXIT_USAGE


# ------------------------------------------------------------------ status


def test_status_reports_an_absent_pack(tmp_path, world, capsys):
    assert run(["status"], tmp_path) == cli.EXIT_OK
    out = capsys.readouterr().out
    assert "demo" in out
    assert "not present" in out


def test_status_never_prints_the_password(tmp_path, world, monkeypatch, capsys):
    monkeypatch.setenv(PASSWORD_ENV, "s3cret-value")
    run(["status"], tmp_path)
    assert "s3cret-value" not in capsys.readouterr().out


# ------------------------------------------------------------------- check


def test_check_reports_an_update_and_changes_nothing(
    tmp_path, world, fake_github, fake_client, capsys
):
    code = run(["check"], tmp_path)
    out = capsys.readouterr().out

    assert code == cli.EXIT_UPDATE_AVAILABLE
    assert "update available" in out
    assert "Nothing was changed" in out
    assert fake_github.downloads == []
    assert fake_client.sent == []
    assert not (world / "datapacks/demo").exists()


def test_check_says_so_when_up_to_date(tmp_path, world, fake_github, capsys):
    (world / "datapacks/demo").mkdir(parents=True)
    (world / "datapacks/demo/pack.mcmeta").write_text("{}", encoding="utf-8")
    state_path = world / "datapacks/.packd-state.json"
    state_path.write_text(
        json.dumps(
            {
                "version": 1,
                "packs": [
                    {"name": "demo", "sha": "b" * 40, "installed_at": "", "ref": "", "history": []}
                ],
            }
        ),
        encoding="utf-8",
    )
    assert run(["check"], tmp_path) == cli.EXIT_OK
    assert "up to date" in capsys.readouterr().out


def test_check_survives_an_api_failure(tmp_path, world, fake_github, capsys):
    fake_github.fail_commit = True
    code = run(["check"], tmp_path)
    assert "simulated API failure" in capsys.readouterr().out
    assert code != cli.EXIT_UPDATE_AVAILABLE


# ------------------------------------------------------------------ update


def test_update_in_check_mode_applies_nothing(tmp_path, world, fake_github, fake_client):
    assert run(["update"], tmp_path) == cli.EXIT_OK
    assert fake_github.downloads == []
    assert fake_client.sent == []
    assert not (world / "datapacks/demo").exists()


def test_update_in_approve_mode_with_yes_applies_and_reloads(
    tmp_path, world, fake_github, fake_client, capsys
):
    code = run(["update", "--mode", "approve", "--yes"], tmp_path)
    assert code == cli.EXIT_OK
    assert (world / "datapacks/demo/pack.mcmeta").is_file()
    assert "reload" in fake_client.sent
    assert any(c.startswith("datapack enable file/demo") for c in fake_client.sent)
    assert "1 pack(s) updated" in capsys.readouterr().out


def test_update_in_approve_mode_with_no_applies_nothing(
    tmp_path, world, fake_github, fake_client
):
    assert run(["update", "--mode", "approve", "--no"], tmp_path) == cli.EXIT_OK
    assert fake_github.downloads == []
    assert not (world / "datapacks/demo").exists()


def test_auto_requires_an_explicit_confirmation_flag(
    tmp_path, world, fake_github, fake_client, capsys
):
    """Autonomy must never be a typo away."""
    code = run(["update", "--mode", "auto"], tmp_path)
    assert code == cli.EXIT_USAGE
    assert "--yes-i-mean-auto" in capsys.readouterr().err
    assert fake_github.downloads == []


def test_auto_with_the_flag_applies(tmp_path, world, fake_github, fake_client):
    assert run(["update", "--mode", "auto", "--yes-i-mean-auto"], tmp_path) == cli.EXIT_OK
    assert (world / "datapacks/demo/pack.mcmeta").is_file()


def test_no_reload_writes_files_without_touching_the_server(
    tmp_path, world, fake_github, fake_client, capsys
):
    assert run(["update", "--mode", "auto", "--yes-i-mean-auto", "--no-reload"], tmp_path) == cli.EXIT_OK
    assert (world / "datapacks/demo/pack.mcmeta").is_file()
    assert fake_client.sent == []


def test_invalid_mode_is_a_usage_error(tmp_path, world):
    """argparse rejects the choice itself, which is still exit 2."""
    with pytest.raises(SystemExit) as exc:
        run(["update", "--mode", "yolo"], tmp_path)
    assert exc.value.code == cli.EXIT_USAGE


# --------------------------------------------------------------------- use


def test_use_installs_an_arbitrary_revision(tmp_path, world, fake_github, fake_client):
    sha = "c" * 40
    assert run(["use", sha, "--no-reload"], tmp_path) == cli.EXIT_OK
    assert fake_github.downloads == [(sha, "packs/demo")]
    assert (world / "datapacks/demo/pack.mcmeta").is_file()


def test_use_records_history_so_rollback_works_offline(
    tmp_path, world, fake_github, fake_client
):
    run(["use", "a" * 40, "--no-reload"], tmp_path)
    run(["use", "b" * 40, "--no-reload"], tmp_path)
    state = json.loads((world / "datapacks/.packd-state.json").read_text(encoding="utf-8"))
    pack = state["packs"][0]
    assert pack["sha"] == "b" * 40
    assert pack["history"][0]["sha"] == "a" * 40


# ---------------------------------------------------------------- rollback


def test_rollback_returns_to_the_previous_revision_offline(
    tmp_path, world, fake_github, fake_client, capsys
):
    run(["use", "a" * 40, "--no-reload"], tmp_path)
    run(["use", "b" * 40, "--no-reload"], tmp_path)
    fake_github.downloads.clear()

    assert run(["rollback", "--no-reload"], tmp_path) == cli.EXIT_OK
    assert fake_github.downloads == [], "a stored revision must not be re-downloaded"
    assert "local backup" in capsys.readouterr().out
    state = json.loads((world / "datapacks/.packd-state.json").read_text(encoding="utf-8"))
    assert state["packs"][0]["sha"] == "a" * 40


def test_rollback_without_history_says_so(tmp_path, world, fake_github, capsys):
    code = run(["rollback", "--no-reload"], tmp_path)
    assert code == cli.EXIT_GENERIC
    assert "no previous revision" in capsys.readouterr().err


def test_history_lists_what_is_known(tmp_path, world, fake_github, fake_client, capsys):
    run(["use", "a" * 40, "--no-reload"], tmp_path)
    run(["use", "b" * 40, "--no-reload"], tmp_path)
    assert run(["history"], tmp_path) == cli.EXIT_OK
    out = capsys.readouterr().out
    assert "current" in out and "previous" in out and "offline" in out


# ------------------------------------------------------------------ issues


def test_issues_list_needs_no_server(tmp_path, world, fake_github, fake_client, capsys):
    assert run(["issues", "--list"], tmp_path) == cli.EXIT_OK
    out = capsys.readouterr().out
    assert "#1" in out
    assert fake_client.sent == [], "--list must not connect to the server"


def test_issues_publishes_to_storage_and_refreshes(
    tmp_path, world, fake_github, fake_client, capsys
):
    assert run(["issues"], tmp_path) == cli.EXIT_OK
    assert any(c.startswith("data remove storage macroengine:issues") for c in fake_client.sent)
    assert any(c.startswith("data merge storage macroengine:issues") for c in fake_client.sent)
    assert "function macroengine:api/issues/refresh" in fake_client.sent
    assert "macroengine:issues" in capsys.readouterr().out


def test_published_issue_text_is_escaped(tmp_path, world, fake_github, fake_client):
    """An issue title is attacker-controlled; it must not be able to end the
    string and start a new command."""
    fake_github.open_issues = lambda limit=20, labels=(): [
        __import__("packd.github", fromlist=["Issue"]).Issue(
            number=9,
            title='x",y:1} stop',
            state="open",
            author="attacker",
            created="",
            updated="",
            url="https://example.invalid/9",
            labels=(),
            body="body",
        )
    ]
    assert run(["issues"], tmp_path) == cli.EXIT_OK
    merge = [c for c in fake_client.sent if c.startswith("data merge")][0]
    # The whole command is one `data merge`; nothing after it may be a second
    # command, so the only unescaped quotes are the ones SNBT needs.
    assert "stop" in merge  # the text is present...
    assert '\\"' in merge    # ...and the quote that would have closed it is escaped


def test_issues_requires_rcon_credentials(tmp_path, world, fake_github, monkeypatch, capsys):
    monkeypatch.delenv(PASSWORD_ENV, raising=False)
    monkeypatch.setattr(cli, "_connect", cli.__dict__["_connect"])  # real one
    code = run(["issues"], tmp_path)
    assert code in (cli.EXIT_SERVER, cli.EXIT_GENERIC)
    assert PASSWORD_ENV in capsys.readouterr().err


# --------------------------------------------------------- test-connection


def test_test_connection_without_a_password_is_refused(tmp_path, world, monkeypatch, capsys):
    monkeypatch.delenv(PASSWORD_ENV, raising=False)
    code = run(["test-connection"], tmp_path)
    assert code == cli.EXIT_SERVER
    err = capsys.readouterr().err
    assert PASSWORD_ENV in err
    assert "SECURITY.md" in err
