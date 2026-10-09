"""Source RCON client.

Implements the packet format from
https://developer.valvesoftware.com/wiki/Source_RCON_Protocol:

    Size (4B, LE)  ID (4B, LE)  Type (4B, LE)  Body (NUL-terminated)  0x00

`Size` counts everything after the size field itself, so its minimum is 10
(4 id + 4 type + 1 body NUL + 1 empty-string NUL) and its maximum is 4096.

Two constraints from SECURITY.md section 4 shape this module, and both are
enforced in code rather than left to the caller:

  * **"limited to the minimum set of commands the project needs"** - every
    command passes through :class:`CommandPolicy` before it reaches the socket.
    A command that is not on the allowlist is refused locally and never sent.
  * **"never used as a bridge from a datapack, chat, or player input to a shell
    or the file system"** - this client only ever *sends*. It exposes no way for
    a server response to become a command: :meth:`RconClient.command` returns
    text, and nothing in this package feeds that text back into a command, a
    shell, or a path. Responses are parsed only as data (see
    :mod:`packd.verify`).

The password is never accepted as a constructor default and never logged; see
:mod:`packd.config` for where it comes from.
"""

from __future__ import annotations

import socket
import struct
from typing import Iterable, Sequence

SERVERDATA_AUTH = 3
SERVERDATA_AUTH_RESPONSE = 2
SERVERDATA_EXECCOMMAND = 2
SERVERDATA_RESPONSE_VALUE = 0

MIN_PACKET_SIZE = 10
MAX_PACKET_SIZE = 4096

# Commands this project is allowed to send. Checked as a prefix match against
# the first token(s) so that `data merge storage macroengine:issues {...}` is
# permitted while `data merge storage <anything else>` is not.
#
# Deliberately narrow. Adding an entry here widens what the tool can do to a
# live server, so it should be a considered change rather than a convenience.
DEFAULT_ALLOWLIST: tuple[str, ...] = (
    "reload",
    "datapack enable",
    "datapack disable",
    "datapack list",
    "data merge storage macroengine:issues",
    "data remove storage macroengine:issues",
    "data get storage macroengine:issues",
    "function macroengine:api/issues/",
    "function guikit:api/issues/",
    "scoreboard players get",
    "execute store result score",
)

# Tokens that must never appear in a command we send, whatever the allowlist
# says. RCON bodies are single commands, but some server implementations accept
# `;`-separated or newline-separated batches; refusing them keeps one allowed
# command from smuggling a second one along.
FORBIDDEN_TOKENS: tuple[str, ...] = ("\n", "\r", ";")


class RconError(Exception):
    """Base class for RCON failures."""


class RconAuthError(RconError):
    """The server rejected the password."""


class RconPolicyError(RconError):
    """A command was refused by the local allowlist before being sent."""


class RconProtocolError(RconError):
    """The peer sent something that is not a well-formed RCON packet."""


class CommandPolicy:
    """Decides whether a command may be sent at all.

    The check is local and happens before any I/O, so a rejected command never
    touches the network and never appears in a server log.
    """

    def __init__(self, allowlist: Sequence[str] = DEFAULT_ALLOWLIST) -> None:
        self.allowlist: tuple[str, ...] = tuple(allowlist)

    def check(self, command: str) -> None:
        """Raise RconPolicyError unless `command` is permitted."""
        text = command.strip()
        if not text:
            raise RconPolicyError("refusing to send an empty command")
        for token in FORBIDDEN_TOKENS:
            if token in text:
                raise RconPolicyError(
                    f"refusing command containing {token!r}: RCON bodies must be "
                    f"a single command, not a batch"
                )
        if text.startswith("/"):
            raise RconPolicyError(
                "refusing a leading '/': RCON takes the bare command, and "
                "accepting both forms makes the allowlist ambiguous"
            )
        if not self._matches(text):
            raise RconPolicyError(
                f"command not on the allowlist: {text.split(' ', 1)[0]!r}. "
                f"Allowed prefixes: {', '.join(self.allowlist)}"
            )
        self._check_arguments(text)

    def _matches(self, text: str) -> bool:
        for allowed in self.allowlist:
            if allowed.endswith("/"):
                if text.startswith(allowed):
                    return True
                continue
            if text == allowed or text.startswith(allowed + " "):
                return True
        return False

    @staticmethod
    def _check_arguments(text: str) -> None:
        """Reject dangerous *arguments* to an otherwise-allowed command.

        A prefix match is not enough on its own: `datapack enable file/x` is
        allowed, and so - without this - was `datapack enable file/../../etc`.
        The server would probably refuse that, but the allowlist is the control
        that is supposed to hold, so it checks the path itself.
        """
        marker = " file/"
        index = text.find(marker)
        if index == -1:
            return
        name = text[index + len(marker) :].strip()
        if not name:
            raise RconPolicyError("a `file/` argument is required but was empty")
        if any(part in ("", ".", "..") for part in name.split("/")):
            raise RconPolicyError(
                f"refusing an unsafe datapack path: {name!r}. A datapack name "
                f"must be a single plain directory component."
            )
        if "\\" in name or name.startswith("/") or " " in name:
            raise RconPolicyError(f"refusing an unsafe datapack path: {name!r}")

    def is_allowed(self, command: str) -> bool:
        try:
            self.check(command)
        except RconPolicyError:
            return False
        return True


def encode_packet(request_id: int, packet_type: int, body: str) -> bytes:
    """Build one RCON packet."""
    payload = body.encode("utf-8")
    # Body NUL + empty-string NUL, plus the 8 bytes of id and type.
    size = len(payload) + 10
    if size > MAX_PACKET_SIZE:
        raise RconProtocolError(
            f"body too large for one RCON packet: {len(payload)} bytes "
            f"(max body is {MAX_PACKET_SIZE - 10})"
        )
    return struct.pack("<iii", size, request_id, packet_type) + payload + b"\x00\x00"


def decode_packet(data: bytes) -> tuple[int, int, str]:
    """Parse one RCON packet body from `data` (which excludes the size field)."""
    if len(data) < 10:
        raise RconProtocolError(f"short packet: {len(data)} bytes, need at least 10")
    request_id, packet_type = struct.unpack("<ii", data[:8])
    body = data[8:]
    if not body.endswith(b"\x00\x00"):
        # Tolerate a single terminator: the spec wants two, but a peer that
        # sends one is still parseable and failing here would be more annoying
        # than useful.
        if not body.endswith(b"\x00"):
            raise RconProtocolError("packet body is not NUL-terminated")
        body = body[:-1]
    else:
        body = body[:-2]
    return request_id, packet_type, body.decode("utf-8", errors="replace")


class RconClient:
    """A minimal Source RCON client.

    Usage::

        with RconClient("127.0.0.1", 25575, password) as c:
            reply = c.command("datapack list")

    The host defaults to loopback because SECURITY.md section 4 requires RCON to
    be bound to 127.0.0.1 or a firewalled network and never exposed publicly.
    """

    def __init__(
        self,
        host: str = "127.0.0.1",
        port: int = 25575,
        password: str = "",
        *,
        timeout: float = 10.0,
        policy: CommandPolicy | None = None,
    ) -> None:
        self.host = host or "127.0.0.1"
        self.port = int(port)
        self._password = password
        self.timeout = float(timeout)
        self.policy = policy or CommandPolicy()
        self._sock: socket.socket | None = None
        self._next_id = 1

    # ------------------------------------------------------------------ setup

    def __enter__(self) -> "RconClient":
        self.connect()
        return self

    def __exit__(self, *exc: object) -> None:
        self.close()

    def connect(self) -> None:
        """Open the socket and authenticate."""
        self._sock = socket.create_connection((self.host, self.port), timeout=self.timeout)
        self._sock.settimeout(self.timeout)
        # Minecraft answers an auth request with an empty RESPONSE_VALUE and
        # then an AUTH_RESPONSE whose id is the request id on success and -1 on
        # failure. Drain both rather than assuming the first reply is the
        # verdict.
        self._send(1, SERVERDATA_AUTH, self._password)
        verdict = -1
        for _ in range(2):
            request_id, packet_type, _body = self._recv()
            if packet_type == SERVERDATA_AUTH_RESPONSE:
                verdict = request_id
                break
        if verdict != 1:
            self.close()
            raise RconAuthError(
                "RCON authentication failed (wrong password, or RCON is "
                "disabled on the server)"
            )
        self._next_id = 2

    def close(self) -> None:
        if self._sock is not None:
            try:
                self._sock.close()
            finally:
                self._sock = None

    # ------------------------------------------------------------------- I/O

    def _send(self, request_id: int, packet_type: int, body: str) -> None:
        assert self._sock is not None, "not connected"
        self._sock.sendall(encode_packet(request_id, packet_type, body))

    def _recv(self) -> tuple[int, int, str]:
        assert self._sock is not None, "not connected"
        header = self._recv_exactly(4)
        (size,) = struct.unpack("<i", header)
        if size < MIN_PACKET_SIZE or size > MAX_PACKET_SIZE:
            raise RconProtocolError(
                f"implausible packet size {size} (valid range "
                f"{MIN_PACKET_SIZE}..{MAX_PACKET_SIZE})"
            )
        return decode_packet(self._recv_exactly(size))

    def _recv_exactly(self, count: int) -> bytes:
        assert self._sock is not None, "not connected"
        chunks = []
        remaining = count
        while remaining > 0:
            chunk = self._sock.recv(remaining)
            if not chunk:
                raise RconProtocolError(
                    f"connection closed after {count - remaining} of {count} bytes"
                )
            chunks.append(chunk)
            remaining -= len(chunk)
        return b"".join(chunks)

    # -------------------------------------------------------------- commands

    def command(self, command: str) -> str:
        """Send one command and return the concatenated response text.

        Refuses anything the policy does not allow. Raises RconPolicyError
        before any network I/O in that case.
        """
        if self._sock is None:
            raise RconError("not connected - use RconClient as a context manager")
        self.policy.check(command)

        request_id = self._next_id
        self._next_id += 1
        self._send(request_id, SERVERDATA_EXECCOMMAND, command)

        # A response can span several packets. The documented way to learn when
        # it is complete is to send an empty RESPONSE_VALUE and wait for the
        # echo, so every fragment of the real answer has already arrived.
        sentinel = self._next_id
        self._next_id += 1
        self._send(sentinel, SERVERDATA_RESPONSE_VALUE, "")

        parts: list[str] = []
        while True:
            packet_id, _packet_type, body = self._recv()
            if packet_id == sentinel:
                break
            if packet_id == request_id:
                parts.append(body)
        return "".join(parts)

    def commands(self, commands: Iterable[str]) -> list[str]:
        """Send several commands in order, returning each response."""
        return [self.command(c) for c in commands]

    # ------------------------------------------------------------- redaction

    @staticmethod
    def safe_repr(host: str, port: int) -> str:
        """A connection description that cannot leak the password."""
        return f"{host}:{port}"
