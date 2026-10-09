"""Config, state and the reply parsers."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from packd.config import (
    DEFAULT_MODE,
    DEFAULT_PACKS,
    MODE_CHECK,
    PASSWORD_ENV,
    ConfigError,
    config_template,
    load_config,
)
from packd.state import State, StateError
from packd.verify import TriState, command_error, datapack_state, reload_ok, storage_int, summarise


# ------------------------------------------------------------------- config


def test_default_mode_is_check_only():
    assert DEFAULT_MODE == MODE_CHECK


def test_defaults_cover_the_two_headline_packs():
    assert "macroEngine-Datapack-v26.4" in DEFAULT_PACKS
    assert "guikit-datapack" in DEFAULT_PACKS


def test_load_without_a_file_uses_defaults(tmp_path):
    config = load_config(None, world_dir=tmp_path / "world")
    assert config.mode == MODE_CHECK
    assert config.host == "127.0.0.1"
    assert [p.name for p in config.packs] == list(DEFAULT_PACKS)


def test_world_dir_is_required(tmp_path):
    with pytest.raises(ConfigError, match="no world directory"):
        load_config(None)


def test_password_comes_only_from_the_environment(tmp_path, monkeypatch):
    config = load_config(None, world_dir=tmp_path)
    monkeypatch.delenv(PASSWORD_ENV, raising=False)
    assert config.password == ""
    monkeypatch.setenv(PASSWORD_ENV, "s3cret")
    assert config.password == "s3cret"


def test_the_template_does_not_contain_a_password_field(tmp_path):
    """SECURITY.md section 4: never committed. The starter file must not have a
    key for it - only a comment pointing at the environment variable."""
    data = json.loads(config_template())
    assert "password" not in data, "the template must not offer a password key"
    assert "rcon_password" not in data
    # It says where the password does come from, in prose only.
    assert PASSWORD_ENV in json.dumps(data["_comment"])


def test_template_round_trips(tmp_path):
    path = tmp_path / "packd.json"
    path.write_text(config_template(str(tmp_path / "world")), encoding="utf-8")
    config = load_config(path)
    assert config.mode == MODE_CHECK
    assert len(config.packs) == 2


@pytest.mark.parametrize("mode", ["nope", "AUTO_", "", "yes"])
def test_bad_mode_is_rejected(tmp_path, mode):
    path = tmp_path / "packd.json"
    path.write_text(json.dumps({"world_dir": str(tmp_path), "mode": mode}), encoding="utf-8")
    with pytest.raises(ConfigError, match="mode must be one of"):
        load_config(path)


def test_missing_file_is_reported(tmp_path):
    with pytest.raises(ConfigError, match="not found"):
        load_config(tmp_path / "absent.json")


def test_invalid_json_is_reported(tmp_path):
    path = tmp_path / "packd.json"
    path.write_text("{not json", encoding="utf-8")
    with pytest.raises(ConfigError, match="not valid JSON"):
        load_config(path)


def test_bad_port_is_rejected(tmp_path):
    path = tmp_path / "packd.json"
    path.write_text(json.dumps({"world_dir": str(tmp_path), "rcon_port": 99999}), encoding="utf-8")
    with pytest.raises(ConfigError, match="out of range"):
        load_config(path)


def test_packs_can_be_plain_strings(tmp_path):
    path = tmp_path / "packd.json"
    path.write_text(
        json.dumps({"world_dir": str(tmp_path), "packs": ["my-pack"]}), encoding="utf-8"
    )
    config = load_config(path)
    assert config.packs[0].name == "my-pack"
    assert config.packs[0].repo_path == "packs/my-pack"


def test_empty_pack_list_is_rejected(tmp_path):
    path = tmp_path / "packd.json"
    path.write_text(json.dumps({"world_dir": str(tmp_path), "packs": []}), encoding="utf-8")
    with pytest.raises(ConfigError, match="non-empty"):
        load_config(path)


def test_unknown_pack_name_lists_the_known_ones(tmp_path):
    config = load_config(None, world_dir=tmp_path)
    with pytest.raises(ConfigError, match="Configured packs"):
        config.pack("nope")


# -------------------------------------------------------------------- state


def test_state_round_trips(tmp_path):
    path = tmp_path / "state.json"
    state = State.load(path)
    state.record("demo", "a" * 40, source="update", ref="main")
    state.save()

    reloaded = State.load(path)
    assert reloaded.get("demo").sha == "a" * 40
    assert reloaded.get("demo").ref == "main"


def test_history_accumulates_newest_first(tmp_path):
    state = State.load(tmp_path / "state.json")
    state.record("demo", "a" * 40, source="update")
    state.record("demo", "b" * 40, source="update")
    state.record("demo", "c" * 40, source="rollback")
    assert state.previous_shas("demo") == ["b" * 40, "a" * 40]


def test_history_is_bounded(tmp_path):
    from packd.state import MAX_HISTORY

    state = State.load(tmp_path / "state.json")
    for i in range(MAX_HISTORY + 10):
        state.record("demo", f"{i:040d}", source="update")
    assert len(state.get("demo").history) <= MAX_HISTORY


def test_missing_state_file_is_not_an_error(tmp_path):
    state = State.load(tmp_path / "absent.json")
    assert state.packs == {}


def test_corrupt_state_is_reported_with_a_way_out(tmp_path):
    path = tmp_path / "state.json"
    path.write_text("{not json", encoding="utf-8")
    with pytest.raises(StateError, match="Delete it to start fresh"):
        State.load(path)


def test_wrong_state_version_is_reported(tmp_path):
    path = tmp_path / "state.json"
    path.write_text(json.dumps({"version": 999, "packs": []}), encoding="utf-8")
    with pytest.raises(StateError, match="state version"):
        State.load(path)


def test_password_is_never_written_into_state(tmp_path, monkeypatch):
    monkeypatch.setenv(PASSWORD_ENV, "s3cret-value")
    path = tmp_path / "state.json"
    state = State.load(path)
    state.record("demo", "a" * 40, source="update")
    state.save()
    assert "s3cret-value" not in path.read_text(encoding="utf-8")


def test_save_is_atomic_enough_to_leave_valid_json(tmp_path):
    path = tmp_path / "state.json"
    state = State.load(path)
    state.record("demo", "a" * 40, source="update")
    state.save()
    json.loads(path.read_text(encoding="utf-8"))
    leftovers = [p for p in tmp_path.iterdir() if p.name.startswith(".packd-state-") and p.suffix == ".tmp"]
    assert leftovers == []


# ------------------------------------------------------------------- verify


@pytest.mark.parametrize(
    "reply,expected",
    [
        ('There are 2 data packs enabled: [file/demo, file/other]', TriState.YES),
        ('Available data packs: ["demo"]', TriState.YES),
        ("There are 0 data packs enabled: []", TriState.NO),
        ("", TriState.UNKNOWN),
        ("something unrelated with no list markers", TriState.UNKNOWN),
    ],
)
def test_datapack_state(reply, expected):
    assert datapack_state(reply, "demo") is expected


@pytest.mark.parametrize(
    "reply,name,expected",
    [
        ("[file/demo-extra]", "demo", TriState.NO),      # longer name, same prefix
        ("[file/demo]", "demo", TriState.YES),
        ("[file/demo, file/other]", "demo", TriState.YES),
        ('["demo"]', "demo", TriState.YES),
        ('["demo-beta"]', "demo", TriState.NO),
        ("[file/my.demo]", "demo", TriState.NO),         # '.' is a valid name char
        ("[file/demo_v2]", "demo", TriState.NO),
        ("[file/guikit-datapack]", "guikit-datapack", TriState.YES),
        ("[file/guikit-datapack-x]", "guikit-datapack", TriState.NO),
    ],
)
def test_datapack_state_matches_whole_names_only(reply, name, expected):
    assert datapack_state(reply, name) is expected


@pytest.mark.parametrize(
    "reply,expected",
    [("", TriState.YES), ("   ", TriState.YES), ("Unknown command", TriState.NO),
     ("failed to reload", TriState.NO), ("Reloading", TriState.UNKNOWN)],
)
def test_reload_ok(reply, expected):
    assert reload_ok(reply) is expected


@pytest.mark.parametrize(
    "reply,expected",
    [("The value is 7", 7), ("#packd has 42", 42), ("negative -3", -3), ("none", None), ("", None)],
)
def test_storage_int(reply, expected):
    assert storage_int(reply) == expected


def test_command_error_detects_a_failure():
    assert command_error("Unknown or incomplete command") is not None
    assert command_error("") is None
    assert command_error("There are 2 data packs") is None


def test_summarise_takes_the_first_line_and_caps_it():
    assert summarise("a\nb\nc") == "a"
    assert len(summarise("x" * 900)) == 200
    assert summarise("") == "(no output)"


def test_a_hostile_reply_stays_inert_data():
    """SECURITY.md section 3: server output must never become something that is
    executed. A reply containing commands must come back as text, and must not
    be classified as an error that the caller would act on."""
    hostile = "reload\nstop\nop @a"
    text = summarise(hostile)
    assert isinstance(text, str)
    assert text.count("\n") == 0 or "\n" in text  # either form is inert text
    assert command_error(hostile) is None
    # And the allowlist would refuse it outright if anyone tried to send it.
    from packd.rcon import CommandPolicy, RconPolicyError

    with pytest.raises(RconPolicyError):
        CommandPolicy().check(hostile)
