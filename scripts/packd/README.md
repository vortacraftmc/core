# packd

Keep the datapacks in a Minecraft world on the revision you actually want —
without deleting the folder, downloading a new one and reloading by hand every
time.

```
$ packd check
  ^ macroEngine-Datapack-v26.4: 4f1c9a2 -> 9b7e3d1 (3 commits)
      9b7e3d1 macroEngine: add api/placeholder, api/data
      7c2a5f0 macroEngine: move _-prefixed internal functions to core/internal
      1d8b4c6 fix: correct the title reset sequence
  = guikit-datapack: up to date

2 pack(s) have an update available. Nothing was changed.
run `packd update --mode approve` to apply interactively.
```

Deleting and re-adding a pack to get one small fix takes longer than the fix
itself, and it loses the ability to go back. `packd` replaces that with: check
what changed, decide, apply, and roll back if it was wrong.

## The three modes

| Mode | Network | Files | Server |
|---|---|---|---|
| `check` *(default)* | read-only | **none** | **none — no RCON connection is made** |
| `approve` | read-only | after you answer yes | after you answer yes |
| `auto` | read-only | yes | yes |

`check` is the default and needs no RCON at all, so installing packd cannot by
itself change a running server. Autonomy is something you turn on, and `auto`
additionally requires `--yes-i-mean-auto` on the command line, so it is never
one typo away.

## Setup

**1. Enable RCON on the server** — it is off by default and should stay that way
for anything you do not control. In `server.properties`:

```properties
enable-rcon=true
rcon.port=25575
rcon.password=<a long random value>
```

Bind it to loopback. `SECURITY.md` section 4 requires RCON to be disabled by
default, bound to `127.0.0.1` or a firewalled network, and never exposed to the
public internet.

**2. Export the password.** It is read from the environment and *nowhere else* —
`SECURITY.md` section 4 forbids committing it or printing it in logs, so packd
will not accept it in the config file:

```bash
export PACKD_RCON_PASSWORD='...'
```

**3. Write a config:**

```bash
packd init --world /path/to/world
$EDITOR packd.json
```

```json
{
  "world_dir": "/path/to/world",
  "mode": "check",
  "host": "127.0.0.1",
  "rcon_port": 25575,
  "ref": "main",
  "packs": [
    { "name": "macroEngine-Datapack-v26.4", "repo_path": "packs/macroEngine-Datapack-v26.4" },
    { "name": "guikit-datapack",            "repo_path": "packs/guikit-datapack" }
  ]
}
```

`world_dir` is the folder that *contains* `datapacks/`.

## Commands

| Command | What it does |
|---|---|
| `packd check` | Report what is newer upstream. **Read-only, no RCON.** Exit 3 if something is available. |
| `packd status` | What is installed, from local state. No network, no RCON. |
| `packd update [--mode M]` | Apply according to the mode. `-y` / `-n` answer the prompt for you. |
| `packd use <sha>` | Install a **specific** revision — older or newer. |
| `packd rollback [sha]` | Return to a revision you have been on. |
| `packd history` | Every revision this tool has installed, plus what is restorable offline. |
| `packd issues [--list]` | Publish open GitHub issues into the game. |
| `packd test-connection` | Prove RCON works before you need it. |

### Flags

| Flag | Where | Meaning |
|---|---|---|
| `-c FILE`, `--config FILE` | all | Config file to read. Default `packd.json` in the working directory. |
| `-w DIR`, `--world DIR` | all | World directory. Overrides `world_dir`, and is accepted both before and after the subcommand. |
| `--pack NAME` | `check`, `update`, `use`, `rollback`, `history`, `issues` | Operate on one pack instead of every configured one. **Required by `use` and `rollback`** when more than one pack is configured, so neither can guess which pack you meant to move. |
| `--no-reload` | `update`, `use`, `rollback`, `issues` | Write the files and stop; never open a socket. Leaves `/reload` to you. |
| `--mode {check,approve,auto}` | `update` | Override the configured mode for one run. `auto` additionally needs `--yes-i-mean-auto`. |
| `-y`, `--yes` | `update` | Answer "yes" to the approve prompt, for scripting. |
| `-n`, `--no` | `update` | Answer "no" to the approve prompt. |
| `--force` | `init` | Overwrite an existing `packd.json` instead of refusing. |
| `--list` | `issues` | Print the issues that would be published and stop — no RCON, nothing written. |
| `--namespace NS` | `issues` | Namespace the refresh function lives in. Default `macroengine`. |
| `--storage ID` | `issues` | Storage to write. Default `macroengine:issues`. |
| `--label L` | `issues` | Only publish issues carrying this label. Repeatable. |
| `--limit N` | `issues` | Stop after N issues. Default 15, matching the slots the datapack renders. |

Every command exits non-zero when it did not do what you asked: `1` generic failure, `2`
usage, `3` an update is available (`check`), `4` the server refused the connection or the
command. That makes `packd check` usable directly in CI.

### Going back to an older commit

This is the part that deleting and reinstalling cannot do. Every revision packd
replaces is kept under `<world>/datapacks/.packd-backups/`, named after the
revision it *contains*, so rolling back does not need the network:

```bash
packd history                 # what have I been on?
packd rollback                # the previous one
packd rollback 4f1c9a2        # a specific one
packd use 1d8b4c6             # any commit at all, fetched from GitHub
```

`rollback` prefers the local backup and only reaches for GitHub when the
revision is not stored, so it works while the network is down — which is often
exactly when you need it.

## `macroengine:issues`

Datapacks cannot make network requests, so the issue list is *pushed* to them:

```bash
packd issues            # fetch open issues, publish them to the server
```

```
> /function macroengine:issues
[macroEngine] open issues (4)  fetched 2026-10-09T11:02:41Z
  #142 macroEngine: title reset leaves stale formatting   Legends11
  #139 guikit tab widget loses state on /reload            someone
```

Hovering a line shows the author, last update, labels and the first line of the
body. Clicking opens the issue in the browser. `packd issues --list` prints the
same list in the terminal without touching the server.

An RCON body cannot exceed 4096 bytes, so packd measures what it builds and
degrades — first dropping body previews, then trimming the list — until every
command is actually sendable. The header reports how many issues were included,
so a truncated list is never mistaken for a complete one.

## Security

`SECURITY.md` sections 3 and 4 constrain this tool, and both are enforced in
code rather than left as documentation.

**The flow is one-way.** packd sends to the server; the server never instructs
packd. `macroengine:issues` only *reads* the storage packd wrote. Nothing reads
a datapack-written file, watches for in-game state, or turns server output into
a command, a path or a shell invocation. `packd.verify` parses replies strictly
as data.

**Commands are allowlisted.** Every command passes `CommandPolicy` before it
reaches the socket, and a refusal happens locally — the command never appears in
a server log. The list is deliberately short:

```
reload · datapack enable|disable|list · data merge|remove|get storage macroengine:issues
function macroengine:api/issues/ · function guikit:api/issues/ · scoreboard players get
```

A prefix match alone is not enough, and the tests say so: `datapack enable
file/../../etc` starts with an allowed prefix. The policy therefore also
validates the `file/` argument itself, and refuses newlines, `;` and a leading
`/` so one allowed command cannot smuggle a second one along.

**Issue text is escaped.** Anyone can open a GitHub issue, so titles and bodies
are attacker-controlled and end up inside a command string. `packd.issues`
escapes rather than interpolates, and `tests/test_issues.py` asserts that a
title like `x",y:1} stop` stays inside one SNBT string.

**The password is never stored.** It is read from `PACKD_RCON_PASSWORD` on
access, so it is not held on the config object, not written to the state file,
and not printed. `Config` has no field for it.

**Writes are staged.** A new revision is materialised in a temporary directory
and moved into place; if anything fails, the previous revision is put back. An
interrupted update leaves the old pack working rather than a half-written one.

### What it does not do

- No shell execution, no file watcher, no bridge from in-game input to anything.
- No writes to GitHub. The API client is read-only.
- No password in the config file, the state file, or the output.
- No automatic update unless you ask for `auto` twice.

## Install

From the monorepo:

```bash
pip install ./scripts/packd              # from a clone
pip install "git+https://github.com/vortacraftmc/core.git#subdirectory=scripts/packd"
```

Or run it in place — there are no runtime dependencies, only the standard
library:

```bash
cd scripts/packd
python3 -m packd check
```

## Tests

```bash
cd scripts/packd
pip install pytest
python3 -m pytest tests/ -q
```

The RCON tests run against an in-process server on a real TCP socket
(`tests/fake_rcon_server.py`), so the protocol implementation is exercised
end to end — authentication success and failure, multi-packet response
reassembly, and the allowlist. No Minecraft server is required.

## Related

- [`SECURITY.md`](../../SECURITY.md) sections 3 and 4 — the constraints above
- [`scripts/gui_generator`](../gui_generator) — generates GUI datapacks
- [`scripts/dp-depman`](../dp-depman) — datapack dependency resolution
