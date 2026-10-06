# vortacraftmc/core

Consolidated monorepo for the vortacraftmc ecosystem.

## Structure

- `mods/`      — Fabric mods
- `packs/`     — Datapacks / resource packs
- `scripts/`   — Helper scripts and tools
- `examples/`  — Templates, example Fabric mods, example datapacks, test files
- `archived/`  — Reserved for projects no longer developed but kept for reference (registry: `archived/archive.json`, validate with `scripts/check_archive.py`)
- `other/`     — Reserved for content that doesn't fit another category (registry: `archived/archive.json`, validate with `scripts/check_archive.py`)

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
