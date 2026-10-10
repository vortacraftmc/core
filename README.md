# vortacraftmc/core

Monorepo for VortaCraftMC: Fabric mods, Minecraft datapacks and resource
packs, plus the datapack tooling built around them.

<!--
This opening line is the repository's GitHub description verbatim. Change one,
change the other:
  curl -X PATCH -H "Authorization: Bearer $TOKEN" \
    https://api.github.com/repos/vortacraftmc/core \
    -d '{"description": "<the new line>"}'
They had already drifted apart once ("Consolidated monorepo for the
vortacraftmc ecosystem."), which is circular - the organization *is*
vortacraftmc, so the description said nothing about what is in here.
-->

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

Pushes and pull requests trigger the `build.yml` workflow, named **`CI`**. Its two jobs are `Verify & package` and `Publish release`; the first runs `buildAll` and `lint` across all subprojects and uploads build artifacts. See `.github/workflows/build.yml` for the full pipeline, including the release-publishing job.

The workflow has three checks with **different levels of enforcement**:

| Check | Enforced? | Notes |
|---|---|---|
| `build` (`buildAll`) | yes | failure fails the job |
| Gradle `lint` | yes | step is `continue-on-error`, but "Final summary" re-fails the job |
| Datapack lint (`scripts/lint_datapacks.sh`, Mecha) | yes | step is `continue-on-error` for diagnostics, but the script propagates Mecha's exit status, so "Release gate" blocks publishing and "Final summary" fails the job |

All three checks are enforced. (The datapack lint used to be advisory only: the
script ended in an unconditional `exit 0` while the step was `continue-on-error`,
making it a no-op that could never fail a build. Mecha 0.101.0 validates all
3681 `.mcfunction` files here and passes with zero errors, so it was made
enforcing on 2026-10-07. Set `LINT_WARN_ONLY=1` for a one-off advisory run.)

The datapack lint still skips the paths listed in `IGNORE_PATHS` at the top of
`scripts/lint_datapacks.sh` (`archived/*`, `packs/cmdTunnel-datapack/*` and two
26.x `time query` files in `macroEngine-Datapack-v26.4`). Mecha only checks
command *syntax* — it does not load the pack, so a green run is not proof that a
datapack behaves correctly.

## History

This monorepo consolidates projects that were previously scattered across
individual repositories under the `runtoolkit` GitHub organization
(TunnelScript, LeftClickDetection, dp-depman, RTWrapper, datapack-fixer, template-datapack, InteractionClickDetection,
cmdTunnel-datapack, dpgen, TEMPLATE-MOD, macroEngine, guigen). That
organization has since been retired in favor of `vortacraftmc`; the old repos
are archived with a pointer to this monorepo, and are not otherwise
maintained.

> **Correction (2026-10-08).** Earlier revisions of this list also named
> `inv_gui`, and a later paragraph warned against using it because its
> licensing as a [rarula/Sketch](https://github.com/rarula/Sketch) fork had
> never been cleared. **No `inv_gui` pack has ever existed in this
> repository** - `git log --all --diff-filter=A -- '*inv_gui*'` returns
> nothing, and no directory, `pack.mcmeta` or namespace by that name is
> present. The warning was about a project that was discussed but never
> merged in, so both the list entry and the paragraph have been removed
> rather than kept as a caveat about absent code.

**Original source:** this project originated as [`runtoolkit/suite`](https://github.com/runtoolkit/suite)
by **Runtoolkit**. It is maintained here as `vortacraftmc/core`; the original
copyright notices in each `LICENSE`/`NOTICE` file are preserved.

