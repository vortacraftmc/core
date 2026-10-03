# ARCHIVED: LeftClickDetection

> **Frozen, reference-only (archived 2026-10-03).** No feature updates; only fixes for significant issues. Do not deploy on a live server without reviewing the code.

## Load approval

The `minecraft:load` / `minecraft:tick` hooks of this pack are routed through `vcm_archive_leftclickdetection:gate_load` / `vcm_archive_leftclickdetection:gate_tick`. The original hooks (kept unchanged in the `orig_load` / `orig_tick` function tags of that namespace) only run after an operator approves:

```mcfunction
/function vcm_archive_leftclickdetection:info      # read the risks
/function vcm_archive_leftclickdetection:confirm   # approve and run the original load hooks
/function vcm_archive_leftclickdetection:revoke    # withdraw approval (tick hooks stop immediately)
```

Limits: the gate only holds back the load/tick hooks. Functions and function tags that other packs or players call directly are **not** blocked. Approval is stored in the world (`vcm_archive` scoreboard, fake player `#leftclickdetection`).

## Risks

1. **Operator-level execution.** Datapack functions run with full command permissions and the load/tick hooks start automatically, with no prompt. A malicious or buggy pack can give operator status, kick/ban players, delete items or data and break the world.
2. **In-game damage, not a PC virus.** Datapacks cannot read files, use the network or run OS code (unlike mod .jar files). The damage is limited to the game world and server.
3. **Parser-bug carrier.** Loading an untrusted world feeds attacker-controlled data to the game's parsers (NBT, text components, commands). A game or library bug can then be triggered just by loading it (example: Log4Shell, unpatched game versions up to 1.18, fixed Dec 2021). Keep the game updated and open untrusted worlds with a separate account/profile or VM.
4. **Version drift.** Targets pack format 26-101. Formats and command syntax change almost every release; this pack is not maintained against newer versions and may break or misbehave.
5. **No support.** Frozen reference code, provided as is without warranty (see LICENSE). Only fixes for significant issues are considered.

This is a general risk notice, not a vulnerability report for this pack.
