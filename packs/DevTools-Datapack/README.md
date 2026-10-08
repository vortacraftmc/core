# DevTools-Datapack

Development-only helpers split out of the production packs. **Not** listed in
`merge-manifest.json`, so it never reaches a release build. Load it next to the
pack under test; the files live in that pack's own namespace.

| Function | Pack under test | What it does |
|---|---|---|
| `macroengine:api/cmd/other/multi_cmd/selftest` | macroEngine | Runs the condition-gate selftest (run as a player: `execute as <player> at @s run function ...`) |
| `macroengine:api/cmd/other/multi_cmd/debug` | macroEngine | Diagnoses one queue entry (shape, `@s`, verdict, body) |
| `macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case` / `selftest_assert` | macroEngine | Internal helpers of the selftest |
| `guikit:internal/selftest` | guikit-datapack | Checks that the widget `clear` filter does not match non-widget items |
