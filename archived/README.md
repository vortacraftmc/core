# archived/

Frozen, reference-only projects. **Do not deploy on a live server without review.**

> **Current contents: none.** `archive.json` has a single entry, the retired
> `runtoolkit/suite` repository, registered with `"path": null` because its
> code lives elsewhere - so there is no archived code in this directory, only
> this README, the registry and its schema. The rules below describe what
> happens *when* a project is moved here; today `packs/` holds all 14 live
> packs and nothing has been retired into `archived/`.
Nothing here is built, zipped or merged: `packs/` is the only tree the Gradle
tasks (`zipPacks`, `checkPacks`, `mergeDatapacks`) scan, and `archived/` is
deliberately outside it.

`archive.json` is the registry (schema: `archive.schema.json`). Validate with:

    ./gradlew checkArchive          # also runs automatically before zipPacks, mergeDatapacks and check
    ./gradlew printArchiveList      # list registry entries
    python3 scripts/check_archive.py   # standalone, no Gradle needed

`checkArchive` additionally fails if an archived project is still under `packs/`
or still listed in `packs/merge-manifest.json` `include`. `-PcheckArchiveStrict=true`
turns warnings (e.g. missing successor) into failures.

## Repository-level pause

Since 2026-10-04 the whole repository is also on a maintenance pause (expected until at least
2027–2028; see the root `README.md`, "Project status"). That is separate from the per-project
archive below: the datapacks here are retired, the repository itself is paused and not archived
on GitHub. Nothing in this folder will be fixed or re-checked during the pause, so assume every
`known_issues` entry in `archive.json` is still open.

## Archiving a project

1. `git mv packs/<name> archived/<name>` (or set `"path": null` if the code lives
   elsewhere).

   > **Note:** this repository used to ship a datapack immutability lock
   > (`packs/.datapack-lock.json` + `scripts/datapack_lock/check_lock.py`). It was
   > removed on 2026-10-08 because it enforced nothing: the workflow it named
   > (`.github/workflows/datapack-immutability.yml`) never existed and no workflow
   > or Gradle task invoked the checker, so `locked: true` was a label, not a
   > guard. Archiving is therefore a plain `git mv` plus a registry entry - there
   > is no unlock step.
2. Add an entry to `archive.json`: `status`, `archived_on`, `reason`, `last_version`,
   `license`, `deploy`, `successor`, and any `known_issues`.
3. Remove it from `packs/merge-manifest.json` `include` if listed.
4. Update the project's README with a pointer to its successor.
5. Run `./gradlew checkArchive`.

## Restoring

Move the folder back to `packs/`, delete its registry entry, re-run the
watermark/pack checks (`./gradlew checkOriginWatermarks checkPacks`).

## Rules

- Only fixes for significant issues; no feature PRs against archived projects (see `NOTICE.md`).
- Keep each project's `LICENSE` and `THIRD_PARTY_LICENSES.md` intact.
- Low-risk findings in archived projects are documented in `known_issues`, not necessarily fixed (see `SECURITY.md`).
