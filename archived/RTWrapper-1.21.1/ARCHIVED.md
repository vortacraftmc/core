# RTWrapper - ARCHIVED

Status: **archived** on 2026-10-03 (vortacraftmc/core). Read-only reference, no further fixes planned, deploy not recommended. Registry entry: `archived/archive.json`.

## Risks to keep in mind

- Unmaintained: no further fixes planned (see `archived/archive.json`, `deploy: not_recommended`).
- Datapacks cannot reach the OS or network, but they run commands at the function permission level (default 2) and can lag or crash a server (unbounded recursion, huge `/fill` or `/forceload`), and can corrupt world, scoreboard and NBT data.
- Read every `.mcfunction` before use, back up the world, and try it in a throwaway world first.
- Only use copies taken from this repository. Forks and "datapack to mod converter" outputs are not covered by `SECURITY.md`; compare them against the source here.
- Do not expose its functions to untrusted players, other packs or command blocks you do not control.
- Executes wrapped commands from queued requests in `rtwrapper:api` storage. Any pack or function that can write to that storage can cause command execution.

## Load gates

This pack ships a load gate under `rtwrapper:gate/r1_21_1/`. It never blocks server startup; the pack simply stays inert until an operator confirms it.

| # | Gate | What it does |
|---|------|--------------|
| 0 | Archive notice | `say` on every load (console and chat) with the risk reminder. |
| 1 | Version / format | `confirm` needs `{format:48}` (this build's data pack format). Detecting the game version from inside `mcfunction` is not possible, so this is an explicit operator handshake, not auto-detection. RTWrapper variants share one namespace; if two variants run their gate in the same tick both are locked. |
| 2 | Confirmation | Pack tick, load entries and guarded sinks do nothing until `confirm` succeeds. The confirmation is stored per pack version (`rtwrapper:gate/r1_21_1` `confirmed`) and is re-armed when the version changes. |
| 3 | Lockdown | `lock` is a kill switch for tick, load entries and guarded sinks; `unlock` re-runs the gate. |
| 4 | Reload breaker | More than 5 loads with gaps of 200 ticks or less lock the pack automatically. |
| 5 | Sink guard | Macro command sinks and privileged wrappers return immediately unless the state is `active`. |

### Operator steps

```mcfunction
/tag <you> add rtwrapper.gate_admin
/function rtwrapper:gate/r1_21_1/confirm {format:48}
# emergency stop / resume
/function rtwrapper:gate/r1_21_1/lock
/tag <you> add rtwrapper.gate_admin
/function rtwrapper:gate/r1_21_1/unlock
# inspect
/data get storage rtwrapper:gate/r1_21_1
```

Players need the `gate_admin` tag (consumed on use); the server console and command blocks have no executing entity and need no tag.

### Limits (read these)

- The gate is an operator safeguard, not a sandbox. Anyone who can run `/tag` and `/function` can confirm.
- Functions already scheduled with `/schedule` before a lock keep running, and any command wrapper that is not listed below stays callable.
- Changing the pack version re-arms confirmation; changing the data pack format of the server does not (there is no way to detect it).

### Guarded sinks

- `rtwrapper:core/run/run_next`
- `rtwrapper:core/run/run_actions`
- `rtwrapper:core/wrappers/handler/main`
