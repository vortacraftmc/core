# vortacraftmc/core

Consolidated monorepo for the vortacraftmc ecosystem.

## Project status (maintenance paused)

**Maintenance paused since 2026-10-04 — not permanently archived.** The
maintainer is expected to be inactive on GitHub until at least 2027–2028.
Issues, pull requests and security reports may go unanswered, and no fixes
or releases are planned during the pause.

The repository is still writable and CI still runs on push; the pause is an
availability statement, not a read-only archive. `archived/` is a separate,
per-project concept — see `archived/README.md`.

## Structure

- `mods/`        — Fabric mods (Gradle subprojects, auto-discovered by `settings.gradle`)
- `packs/`       — Datapacks / resource packs
- `scripts/`     — Helper scripts and tools
- `examples/`    — Templates, example Fabric mods, example datapacks, test files
- `build-logic/` — Shared Gradle script (`shared-fabric-mod.gradle`) applied by the mod subprojects
- `archived/`    — Reserved for projects no longer developed but kept for reference (registry: `archived/archive.json`, validate with `scripts/check_archive.py`)

Content that does not fit another category is not given its own directory.
Register it in `archived/archive.json` with `"kind": "other"` instead; the
schema (`archived/archive.schema.json`) enumerates the valid kinds.

---

## Building

This repo uses Gradle to build all Fabric mod subprojects.

### Requirements

- JDK 25
- Gradle Wrapper (included, no separate Gradle install needed)

### Build all subprojects

```bash
./gradlew buildAll
```

This runs the build task across every subproject under `mods/` and produces mod JARs. Output JARs land in each subproject's `build/libs/` directory.

### Lint all subprojects

```bash
./gradlew lint
```

### Build a single subproject

```bash
./gradlew :mods:<subproject-name>:build
```

### CI

Pushes and pull requests trigger the `build.yml` workflow (Build & Lint), which runs `buildAll` and `lint` across all subprojects and uploads build artifacts. See `.github/workflows/build.yml` for the full pipeline, including the release-publishing job.

The workflow has three checks with **different levels of enforcement**:

| Check | Enforced? | Notes |
|---|---|---|
| `build` (`buildAll`) | yes | failure fails the job |
| Gradle `lint` | yes | step is `continue-on-error`, but "Final summary" re-fails the job |
| Datapack lint (`.github/workflows/lint.sh`, Mecha) | **no — advisory only** | the script ends in an unconditional `exit 0` ("Warning Mode") and the step is `continue-on-error`, so this check cannot fail the build. Mecha errors are reported as warnings only |

The datapack lint also skips the paths listed in `IGNORE_PATHS` at the top of
`.github/workflows/lint.sh` (`archived/*`, `packs/cmdTunnel-datapack/*` and two
26.x `time query` files in `macroEngine-Datapack-v26.4`). Do not read a green
CI run as proof that a datapack change is valid — load the pack.

## History

This monorepo consolidates projects that were previously scattered across
individual repositories under the `runtoolkit` GitHub organization
(TunnelScript, LeftClickDetection, dp-depman, RTWrapper, datapack-fixer, template-datapack, InteractionClickDetection,
cmdTunnel-datapack, dpgen, TEMPLATE-MOD, inv_gui, macroEngine, guigen). That
organization has since been retired in favor of `vortacraftmc`; the old repos
are archived with a pointer to this monorepo, and are not otherwise
maintained.

**Original source:** this project originated as [`runtoolkit/suite`](https://github.com/runtoolkit/suite)
by **Runtoolkit**. It is maintained here as `vortacraftmc/core`; the original
copyright notices in each `LICENSE`/`NOTICE` file are preserved.

**Note on `inv_gui`:** this pack was originally brought in as a renamed fork
of [rarula/Sketch](https://github.com/rarula/Sketch). Its licensing relative
to the upstream project was never properly cleared before the fork was
built out, so **use of `inv_gui` is not recommended** until that is
resolved. It is kept in this monorepo for reference and possible
reimplementation, not as a supported component.
