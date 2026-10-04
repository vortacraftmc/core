# Credits & AI-assistance disclosure

This file records which parts of the repository were written or changed with AI assistance, so that
AI involvement is visible in the repository itself and not only through commit authorship.

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
