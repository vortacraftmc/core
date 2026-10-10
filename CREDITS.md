# Credits & AI-assistance disclosure

This file records which parts of the repository were written or changed with AI assistance, so that
AI involvement is visible in the repository itself and not only through commit authorship.

## 2026-10-10 - fix: placeholder scratch chest_minecart item drop (`@s` rebind reverted)

**Tool:** Claude (Anthropic), working from a prompt by the maintainer. Review status: _pending - update
when reviewed_.

### Changed (AI-assisted edit)

| Path | Change |
|---|---|
| `packs/macroEngine-Datapack-v26.4/.../api/placeholder/_derive.mcfunction` | The scratch item is replaced with air before the chest_minecart is killed, so it no longer drops a `minecraft:stone`. |
| `packs/macroEngine-Datapack-v26.4/.../api/placeholder/_derive.mcfunction`, `_plain.mcfunction` | An earlier AI commit (bb9d972, 0483225) rebound `"@s"` onto the caller via a `macroengine.ph_caller` tag. That was based on an unverified assumption (that `this` in `item modify` is the minecart), and the in-game log (latest.log, 16:06) shows `%player%` already resolved correctly before it. The rebind broke `custom_name` / `lore` (bogus parts, then empty values). It is reverted here. |

### Verification status

- Verified: both files parse with Mecha 0.101.0 (syntax only). In-game log from before the rebind shows `custom_name` resolving `%player%`.
- **Not verified:** that the stone no longer drops; `%health%`, `%food%`, `%xp_level%`, `%dimension%`, `register_score` placeholders in a real server. Whether `string` is empty because of the double quote in a test value (documented refusal in `core/internal/text/concat`) is also unconfirmed.

## 2026-10-10 - refactor: remove dead `multiCommands` storage writes in macroEngine

**Tool:** Claude (Anthropic), working from a prompt by the maintainer. Review status: _pending - update
when reviewed_.

### Changed (AI-assisted edit)

| Path | Change |
|---|---|
| `packs/macroEngine-Datapack-v26.4/.../api/cmd/other/multi_cmd.mcfunction` | Removed `data remove` of `macroengine:engine multiCommands.type` / `.active`; nothing in this call path sets either. |
| `packs/macroEngine-Datapack-v26.4/.../api/cmd/other/multi_cmd_adv.mcfunction` | Same two `data remove` lines removed. |
| `packs/macroEngine-Datapack-v26.4/.../multi_cmd/advanced/run_with_options.mcfunction` | Removed the only writer of `multiCommands.type` (and its "Validate" comment, which described validation that does not exist). Nothing in the repository reads the value. |

### Verification status

- Verified: repo-wide grep shows no remaining reader of `multiCommands.type` / `.active`; `scripts/lint_datapacks.sh` (Mecha 0.101.0) passes.
- **Not verified:** runtime behaviour in a real Minecraft server. Datapacks or tools outside this repository that read `macroengine:engine multiCommands.*` would be affected.

## 2026-10-07 - fix: release assets not found (`packs-latest`)

**Tool:** Claude (Anthropic), working from a prompt by the maintainer. Review status: _pending - update
when reviewed_.

### Changed (AI-assisted edit)

| Path | Change |
|---|---|
| `.github/workflows/build.yml` | `release` job: `files:` now points to `release-assets/*.zip` (the downloaded `release-packs` artifact) instead of `build/packs-dist/*.zip` / `build/dist/*.zip`, which do not exist in that job (no checkout). Added `fail_on_unmatched_files: true` and a duplicate-file-name check in "Collect release assets". |

### Verification status

- Verified: YAML parses; duplicate-name check logic exercised locally with a shell test.
- **Not verified:** an actual GitHub Actions run (needs a push to `main` / `workflow_dispatch`).

## 2026-10-04 - improvements batch + two new Fabric mods

**Tool:** Claude (Anthropic), working from a prompt by the maintainer. Reviewed and merged by a human
maintainer (review status: _pending at the time of writing - update when reviewed_).

### New (AI-written; every new Java file carries an "AI-assisted" header comment)

| Path | What |
|---|---|
| `mods/join-throttle/` | Login-rate limiter mod (1.21.1, Yarn) incl. unit tests |
| `mods/afk-manager/` | Idle detection / `/afk` / optional AFK kick mod (1.21.1, Yarn) incl. unit tests |
| `CREDITS.md` | This file |

### Changed (AI-assisted edits to existing files)

| Path | Change |
|---|---|
| `mods/rtwrapper-mod/build.gradle` | `project.archivesBaseName` (removed in Gradle 9) -> `base.archivesName` |
| `build-logic/shared-fabric-mod.gradle` | Reproducible archives (no timestamps, stable file order) |
| `build.gradle` | Removed ~235 lines of blank padding (whitespace only) |
| `settings.gradle` | Deterministic (sorted) subproject discovery order |
| `mods/TEMPLATE-MOD/gradle/wrapper/gradle-wrapper.properties` | Gradle 9.4.1 -> 9.8.0 (matches root) |
| `.github/workflows/build.yml` | Top-level `permissions: contents: read` (least privilege) |
| `.github/dependabot.yml` | `pip` pointed at the real manifest dir; added `npm` for `scripts/dpgen` |
| `scripts/check_archive.py` | Parity with Gradle `checkArchive` + type guards instead of crashing |
| `scripts/backup-org.sh` | Token passed to `github-backup` via a 0600 temp file instead of argv |

### Verification status at the time of writing

- Verified by running: `check_archive.py` (real registry + malformed inputs), `backup-org.sh` (stubbed
  `github-backup`), YAML parsing of the changed workflow files, and the unit tests of the Minecraft-free
  classes of both new mods.
- **Not verified (no Gradle / Fabric Maven access in the authoring environment):** Gradle configuration of
  all changed `.gradle` files, compilation of the Fabric-facing code (`*Mod.java`, `PlayerManagerMixin`)
  against Minecraft 1.21.1 Yarn mappings, and runtime behaviour in a real server. Treat these as
  needing a CI run and a manual server test before release.
