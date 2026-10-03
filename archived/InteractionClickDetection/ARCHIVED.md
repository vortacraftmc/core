# InteractionClickDetection - ARCHIVED

Status: **archived** on 2026-10-03 (vortacraftmc/core). Read-only reference, no further fixes planned, deploy not recommended. Registry entry: `archived/archive.json`.

## Risks to keep in mind

- Unmaintained: no further fixes planned (see `archived/archive.json`, `deploy: not_recommended`).
- Datapacks cannot reach the OS or network, but they run commands at the function permission level (default 2) and can lag or crash a server (unbounded recursion, huge `/fill` or `/forceload`), and can corrupt world, scoreboard and NBT data.
- Read every `.mcfunction` before use, back up the world, and try it in a throwaway world first.
- Only use copies taken from this repository. Forks and "datapack to mod converter" outputs are not covered by `SECURITY.md`; compare them against the source here.
- Do not expose its functions to untrusted players, other packs or command blocks you do not control.
- Click detection via advancements or interaction entities. Uses the pre-1.21 plural folder layout (`functions/`), so it does not load on 1.21 or newer.
