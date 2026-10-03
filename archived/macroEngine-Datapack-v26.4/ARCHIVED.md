# macroEngine - ARCHIVED

Status: **archived** on 2026-10-03 (vortacraftmc/core). Read-only reference, no further fixes planned, deploy not recommended. Registry entry: `archived/archive.json`.

## Risks to keep in mind

- Unmaintained: no further fixes planned (see `archived/archive.json`, `deploy: not_recommended`).
- Datapacks cannot reach the OS or network, but they run commands at the function permission level (default 2) and can lag or crash a server (unbounded recursion, huge `/fill` or `/forceload`), and can corrupt world, scoreboard and NBT data.
- Read every `.mcfunction` before use, back up the world, and try it in a throwaway world first.
- Only use copies taken from this repository. Forks and "datapack to mod converter" outputs are not covered by `SECURITY.md`; compare them against the source here.
- Do not expose its functions to untrusted players, other packs or command blocks you do not control.
- Executes caller-supplied commands: the `$(cmd)` macro sinks (listed under *Guarded sinks* below) run arbitrary commands, and the `api/cmd/*` wrappers pass unvalidated macro arguments to `op`, `deop`, `ban`, `whitelist`, `datapack`, `function`, `gamerule` and similar. Anything that can reach these functions can use them.

## Load gates

This pack ships a load gate under `macroengine:gate/v26_4/`. It never blocks server startup; the pack simply stays inert until an operator confirms it.

| # | Gate | What it does |
|---|------|--------------|
| 0 | Archive notice | `say` on every load (console and chat) with the risk reminder. |
| 1 | Version / format | `confirm` needs `{format:122}` (this build's data pack format). Detecting the game version from inside `mcfunction` is not possible, so this is an explicit operator handshake, not auto-detection. |
| 2 | Confirmation | Pack tick, load entries and guarded sinks do nothing until `confirm` succeeds. The confirmation is stored per pack version (`macroengine:gate/v26_4` `confirmed`) and is re-armed when the version changes. |
| 3 | Lockdown | `lock` is a kill switch for tick, load entries and guarded sinks; `unlock` re-runs the gate. |
| 4 | Reload breaker | More than 5 loads with gaps of 200 ticks or less lock the pack automatically. |
| 5 | Sink guard | Macro command sinks and privileged wrappers return immediately unless the state is `active`. |

### Operator steps

```mcfunction
/tag <you> add macroengine.gate_admin
/function macroengine:gate/v26_4/confirm {format:122}
# emergency stop / resume
/function macroengine:gate/v26_4/lock
/tag <you> add macroengine.gate_admin
/function macroengine:gate/v26_4/unlock
# inspect
/data get storage macroengine:gate/v26_4
```

Players need the `gate_admin` tag (consumed on use); the server console and command blocks have no executing entity and need no tag.

### Limits (read these)

- The gate is an operator safeguard, not a sandbox. Anyone who can run `/tag` and `/function` can confirm.
- Functions already scheduled with `/schedule` before a lock keep running, and any command wrapper that is not listed below stays callable.
- Changing the pack version re-arms confirmation; changing the data pack format of the server does not (there is no way to detect it).

### Guarded sinks

- `macroengine:api/cmd/as_player`
- `macroengine:api/cmd/execute_if_pred`
- `macroengine:api/cmd/other/run_as_uuid`
- `macroengine:api/cmd/other/run_nearest`
- `macroengine:api/cmd/other/run_random`
- `macroengine:api/cmd/other/run_self`
- `macroengine:api/perm/exec`
- `macroengine:api/perm/run`
- `macroengine:core/internal/api/cmd/other/multi_cmd/exec_macro`
- `macroengine:core/internal/api/trigger/call2`
- `macroengine:core/internal/api/wand/call_cmd`
- `macroengine:core/internal/core/lib/queue_run_cmd`
- `macroengine:core/internal/core/lib/queue_run_cmd_as`
- `macroengine:core/internal/systems/hook/run_cmd`
- `macroengine:core/lib/once_cmd`
- `macroengine:input/private/dialog_capture`
- `macroengine:player/run_cmd_as_uuid_macro`
- `macroengine:api/cmd/ban`
- `macroengine:api/cmd/ban_ip`
- `macroengine:api/cmd/kick`
- `macroengine:api/cmd/op`
- `macroengine:api/cmd/deop`
- `macroengine:api/cmd/whitelist`
- `macroengine:api/cmd/datapack`
- `macroengine:api/cmd/function`
- `macroengine:api/cmd/gamerule`
- `macroengine:api/cmd/effect_give_all`
- `macroengine:api/cmd/publish`
