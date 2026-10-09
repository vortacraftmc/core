"""An in-process Source RCON server, for tests.

Implements enough of the protocol to exercise :mod:`packd.rcon` end to end over
a real TCP socket: authentication (including the failure case), command
execution, multi-packet responses, and the empty-response sentinel that marks
the end of a reply.

Every command received is recorded in :attr:`FakeRconServer.commands`, so a test
can assert both what was sent and - just as important - what was **not** sent.
"""

from __future__ import annotations

import socket
import struct
import threading
from typing import Callable

from packd.rcon import (
    MAX_PACKET_SIZE,
    SERVERDATA_AUTH,
    SERVERDATA_AUTH_RESPONSE,
    SERVERDATA_EXECCOMMAND,
    SERVERDATA_RESPONSE_VALUE,
    encode_packet,
)


class FakeRconServer:
    """A scripted RCON server bound to 127.0.0.1 on an ephemeral port."""

    def __init__(
        self,
        password: str = "secret",
        *,
        responder: Callable[[str], str] | None = None,
        split_after: int = 0,
    ) -> None:
        self.password = password
        self.responder = responder or (lambda _cmd: "")
        # When > 0, replies longer than this are split across packets, so the
        # client's reassembly path is actually covered.
        self.split_after = split_after
        self.commands: list[str] = []
        self.auth_attempts: list[str] = []
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._sock.bind(("127.0.0.1", 0))
        self._sock.listen(4)
        self.port = self._sock.getsockname()[1]
        self._thread: threading.Thread | None = None
        self._stop = threading.Event()

    # ------------------------------------------------------------- lifecycle

    def __enter__(self) -> "FakeRconServer":
        self.start()
        return self

    def __exit__(self, *exc: object) -> None:
        self.stop()

    def start(self) -> None:
        self._thread = threading.Thread(target=self._serve, daemon=True)
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()
        try:
            self._sock.close()
        except OSError:
            pass
        if self._thread is not None:
            self._thread.join(timeout=5)

    # -------------------------------------------------------------- protocol

    def _serve(self) -> None:
        while not self._stop.is_set():
            try:
                conn, _addr = self._sock.accept()
            except OSError:
                return
            with conn:
                conn.settimeout(5)
                self._handle(conn)

    def _handle(self, conn: socket.socket) -> None:
        authenticated = False
        while not self._stop.is_set():
            try:
                header = self._recv_exactly(conn, 4)
                if header is None:
                    return
                (size,) = struct.unpack("<i", header)
                body = self._recv_exactly(conn, size)
                if body is None:
                    return
                request_id, packet_type = struct.unpack("<ii", body[:8])
                payload = body[8:].rstrip(b"\x00").decode("utf-8", errors="replace")

                if packet_type == SERVERDATA_AUTH:
                    self.auth_attempts.append(payload)
                    # Minecraft sends an empty RESPONSE_VALUE first, then the
                    # verdict. Mirror that so the client's drain loop is tested.
                    conn.sendall(encode_packet(request_id, SERVERDATA_RESPONSE_VALUE, ""))
                    ok = payload == self.password
                    verdict = request_id if ok else -1
                    conn.sendall(encode_packet(verdict, SERVERDATA_AUTH_RESPONSE, ""))
                    authenticated = ok
                    continue

                if packet_type == SERVERDATA_EXECCOMMAND:
                    self.commands.append(payload)
                    if not authenticated:
                        conn.sendall(encode_packet(-1, SERVERDATA_RESPONSE_VALUE, "not authenticated"))
                        continue
                    reply = self.responder(payload)
                    for chunk in self._split(reply):
                        conn.sendall(encode_packet(request_id, SERVERDATA_RESPONSE_VALUE, chunk))
                    continue

                if packet_type == SERVERDATA_RESPONSE_VALUE:
                    # The end-of-response sentinel: echo the id back.
                    conn.sendall(encode_packet(request_id, SERVERDATA_RESPONSE_VALUE, ""))
                    continue
            except (OSError, struct.error):
                return

    def _split(self, text: str) -> list[str]:
        if self.split_after <= 0 or len(text) <= self.split_after:
            return [text]
        return [
            text[i : i + self.split_after]
            for i in range(0, len(text), self.split_after)
        ] or [""]

    @staticmethod
    def _recv_exactly(conn: socket.socket, count: int) -> bytes | None:
        chunks = []
        remaining = count
        while remaining > 0:
            try:
                chunk = conn.recv(remaining)
            except OSError:
                return None
            if not chunk:
                return None
            chunks.append(chunk)
            remaining -= len(chunk)
        return b"".join(chunks)


def make_long_reply(marker: str = "x", length: int = 6000) -> str:
    """A reply too big for one RCON packet, to test reassembly."""
    assert length <= MAX_PACKET_SIZE * 4
    return marker * length
