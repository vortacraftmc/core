"""RCON protocol and policy tests, against a real socket."""

from __future__ import annotations

import pytest

from packd.rcon import (
    CommandPolicy,
    RconAuthError,
    RconClient,
    RconError,
    RconPolicyError,
    decode_packet,
    encode_packet,
)

from .fake_rcon_server import FakeRconServer, make_long_reply


# ------------------------------------------------------------------ framing


def test_encode_packet_size_field_excludes_itself():
    packet = encode_packet(7, 2, "hello")
    # 4 id + 4 type + 5 body + 2 terminators = 15, and the size field is not
    # counted in its own value.
    assert len(packet) == 15 + 4
    assert packet[:4] == (15).to_bytes(4, "little")


def test_empty_body_is_the_minimum_packet():
    packet = encode_packet(1, 0, "")
    (size,) = (int.from_bytes(packet[:4], "little"),)
    assert size == 10


def test_roundtrip_preserves_body_and_type():
    request_id, packet_type, body = decode_packet(encode_packet(42, 3, "reload")[4:])
    assert (request_id, packet_type, body) == (42, 3, "reload")


def test_oversized_body_is_refused_before_sending():
    with pytest.raises(Exception, match="too large"):
        encode_packet(1, 2, "x" * 5000)


def test_short_packet_is_a_protocol_error():
    with pytest.raises(Exception, match="short packet"):
        decode_packet(b"\x00\x00")


# --------------------------------------------------------------- connection


def test_auth_success_and_command():
    with FakeRconServer(password="hunter2") as server:
        with RconClient("127.0.0.1", server.port, "hunter2") as client:
            assert client.command("datapack list") == ""
    assert server.auth_attempts == ["hunter2"]
    assert server.commands == ["datapack list"]


def test_wrong_password_raises_auth_error():
    with FakeRconServer(password="hunter2") as server:
        with pytest.raises(RconAuthError):
            with RconClient("127.0.0.1", server.port, "wrong"):
                pass
    assert server.commands == [], "no command may run after a failed auth"


def test_password_is_not_echoed_into_commands():
    with FakeRconServer(password="hunter2") as server:
        with RconClient("127.0.0.1", server.port, "hunter2") as client:
            client.command("reload")
    assert "hunter2" not in server.commands
    assert server.auth_attempts == ["hunter2"]


def test_response_reassembly_across_packets():
    reply = make_long_reply(length=3000)
    with FakeRconServer(responder=lambda _c: reply, split_after=400) as server:
        with RconClient("127.0.0.1", server.port, "secret") as client:
            got = client.command("datapack list")
    assert got == reply
    assert len(got) == 3000


def test_command_before_connect_is_refused():
    client = RconClient("127.0.0.1", 1, "x")
    with pytest.raises(RconError, match="not connected"):
        client.command("reload")


def test_safe_repr_never_includes_the_password():
    assert "pass" not in RconClient.safe_repr("127.0.0.1", 25575).lower()


# ------------------------------------------------------------------- policy


@pytest.mark.parametrize(
    "allowed",
    [
        "reload",
        "datapack enable file/macroEngine-Datapack-v26.4",
        "datapack enable file/guikit-datapack",
        "datapack disable file/guikit-datapack",
        "datapack list",
        "data merge storage macroengine:issues {schema:1}",
        "data remove storage macroengine:issues",
        "function macroengine:api/issues/refresh",
        "function guikit:api/issues/refresh",
    ],
)
def test_allowlisted_commands_pass(allowed):
    CommandPolicy().check(allowed)


@pytest.mark.parametrize(
    "refused",
    [
        "",
        "   ",
        "op @a",                       # not needed by this tool
        "kick player",
        "whitelist add someone",
        "stop",
        "data merge storage other:thing {}",
        "/reload",                     # leading slash is ambiguous
        "reload\nstop",                # batch smuggling via newline
        "reload;stop",                 # batch smuggling via semicolon
        "datapack enable file/../../etc",
        "datapack enable file/",
        "datapack enable file/a b",
        "datapack disable file/..",
        "datapack enable file/.",
        "datapack enable file/a/../b",
    ],
)
def test_non_allowlisted_commands_are_refused(refused):
    with pytest.raises(RconPolicyError):
        CommandPolicy().check(refused)


def test_policy_refuses_before_any_network_io():
    """A rejected command must not reach the socket at all."""
    with FakeRconServer() as server:
        with RconClient("127.0.0.1", server.port, "secret") as client:
            with pytest.raises(RconPolicyError):
                client.command("op @a")
    assert server.commands == [], "the refused command must never be sent"


def test_policy_is_applied_by_the_client_not_just_available():
    with FakeRconServer() as server:
        with RconClient("127.0.0.1", server.port, "secret") as client:
            with pytest.raises(RconPolicyError):
                client.command("stop")
            client.command("reload")
    assert server.commands == ["reload"]


def test_custom_allowlist_narrows_further():
    policy = CommandPolicy(allowlist=("reload",))
    policy.check("reload")
    with pytest.raises(RconPolicyError):
        policy.check("datapack list")
    assert policy.is_allowed("reload") is True
    assert policy.is_allowed("stop") is False
