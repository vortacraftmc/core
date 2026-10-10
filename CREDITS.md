# Credits & AI-assistance disclosure

This file records which parts of the repository were written or changed with AI assistance, so that
AI involvement is visible in the repository itself and not only through commit authorship.

## 2026-10-10 - refactor: remove dead scratch storage and an unused function in macroEngine

**Tool:** Claude (Anthropic), working from a prompt by the maintainer. Review status: _pending - update
when reviewed_.

### Changed (AI-assisted edit)

| Path (under `packs/macroEngine-Datapack-v26.4/data/macroengine/function/`) | Change |
|---|---|
| `core/internal/core/lib/batch/flush_exec.mcfunction` | Removed write/clear of `engine._bfl_id` (never read). |
| `core/internal/core/lib/for_each_list_step.mcfunction`, `core/lib/for_each_list.mcfunction` | Removed write/clear of `engine._felist_i` (never read; the `$felist_i` score is what is used). |
| `core/internal/systems/geo/region_watch/tick_scan.mcfunction` | Removed copy/clear of `engine._rw_watch_list` (never read). |
| `core/internal/systems/math/vec/angle_exec.mcfunction` | Removed write of `engine._vang_cos` (`arccos_lookup` reads the `$vang_dot` score). |
| `core/internal/player/stamp_join.mcfunction` | Deleted: no caller, and `players.<name>.joined_tick` is never read. |

### Verification status

- Verified: raw-name grep over `packs/` finds no remaining reference to any removed name; `scripts/lint_datapacks.sh` (Mecha 0.101.0) passes.
- **Not verified:** runtime behaviour in a real server. External datapacks reading these `_`-prefixed scratch keys would break.

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
