# Contributing to vortacraftmc/core

> **⚠️ Maintenance paused (not permanently archived).** Since 2026-10-04 the maintainer is expected to be inactive on GitHub until at least 2027–2028. Issues, pull requests and security reports may go unanswered, and no fixes or releases are planned. See [Project status](https://github.com/vortacraftmc/core#project-status-maintenance-paused).

Thanks for your interest in contributing to this project.

**Read [NOTICE.md](NOTICE.md) before opening a PR.** It covers the
Gradle/datapack split in this monorepo (what's built by `buildAll` and what
isn't), what a PR should contain, and what will get a PR closed
(obfuscated code, undisclosed behavior, misuse of the macro/command
tooling for griefing or exploit purposes). This guide assumes you've
already read it.

## Getting started

1. Fork or clone the repository.
2. Create a branch for your change:

   ```bash
   git checkout -b your-branch-name
   ```

3. Make your changes.
4. Build and lint before opening a PR:
   ```bash
   ./gradlew buildAll
   ./gradlew lint
   ```

## Branch naming

Use `<type>/<short-description>` in kebab-case, matching the commit type below:

```
fix/macroengine-condition-gate      feat/guikit-radio-tabs
ci/consolidate-lint-jobs            chore/bump-fabric-loader
docs/security-validation-table
```

Avoid the names GitHub generates for web edits (`<user>-patch-1`) and avoid
long-lived catch-all branches. Historical branches in this repository used
`devlop` (a misspelling of "develop") and `<user>-patch-N`; neither is a
pattern to copy.

## Commit messages

This repository uses [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <imperative summary, <= 72 chars>

<optional body: what changed and why, wrapped at 72>
```

`type` is one of `feat`, `fix`, `ci`, `docs`, `chore`, `refactor`, `test`,
`perf`, `build`, `revert`. `scope` is the area touched (`macroEngine`,
`guikit`, `backup`, `deps`, ...) and is optional for repo-wide changes.

A one-word or placeholder subject is not acceptable: an audit of this
repository's history found 34 of 379 commits whose entire message was `.`,
which makes `git log`, `git blame` and every generated changelog useless for
those changes. If you cannot summarise the change in one line, the commit is
probably two commits. Reference related issues or PRs in the body
(`Fixes #123`).

## Pull requests

- Open a PR against the `main` branch.
- Make sure the **`CI`** workflow is green before requesting review. Inside its `Verify & package` job the steps that can fail you are `Build all subprojects` (`./gradlew buildAll`), `Gradle lint` (`./gradlew lint`) and `Lint datapacks` (`scripts/lint_datapacks.sh`, Mecha); `Release gate` then blocks publishing if any of them failed.
- Describe what changed and why in the PR description — and whether the change touches `mods/`, `packs/`, or both, since only the former is covered by `buildAll`.
- Run through the checklist at the bottom of [NOTICE.md](NOTICE.md) before requesting review.

## Security

This project follows a security-first development philosophy, particularly around Minecraft datapack macro injection risks and namespace isolation. If you find a security issue, do **not** open a public issue - use [GitHub's private vulnerability reporting](https://github.com/vortacraftmc/core/security/advisories/new), and fall back to a detail-free public issue only if that is unavailable to you. The full procedure, including what must not be included in a report, is in [SECURITY.md](SECURITY.md).

## Provenance watermark (`_vc_origin.mcfunction`)

Every datapack under `packs/` carries a `_vc_origin.mcfunction` file (under
`data/<namespace>/function/`) that `build.gradle`'s `zipPacks` task checks
for before packaging. This file is not build output and should not be
removed, renamed, or hand-edited in `packs/` by a contributor's PR —
`zipPacks` treats a missing watermark as a build failure, and the project
maintainers ask that it stay untouched in the source tree. Only `build.gradle`
itself (via its `build/packs-remap/` working copy, never `packs/`) and
maintainers acting through the project's own tooling are expected to
touch these files. This is a contribution-conduct expectation, not a
license restriction — the Unlicense in `LICENSE` continues to govern
what anyone may do with a copy of this code once obtained.

## Code style

- Java code should be clear and documented; complex logic should include comments explaining intent.
- Avoid introducing unnecessary dependencies.
- Fabric mod code must remain tick-safe (see project TPS guidelines).

## Questions

Open an issue if something in this guide is unclear or if you need help getting your environment set up.
