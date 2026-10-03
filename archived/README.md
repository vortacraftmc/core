# archived/

Frozen, reference-only projects. **Do not deploy on a live server without review.**
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

## Archiving a project

1. `git mv packs/<name> archived/<name>` (or set `"path": null` if the code lives elsewhere).
   If the pack is `locked: true` in `packs/.datapack-lock.json`, unlock it in a separate
   PR first (see `datapack-immutability.yml`), otherwise CI blocks the move; remove its
   entry from the lock file in the same PR as the move.
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

## Archive notes and load gates

Every datapack here carries an `ARCHIVED.md` (risk reminder), an `[ARCHIVED]` prefix in its `pack.mcmeta`
description and, where it has a load function, a `say` notice on load.

The framework / API packs (`macroEngine-Datapack-v26.4`, `guikit-datapack`, the three `RTWrapper*` builds)
additionally ship a load gate under `<namespace>:gate/<slug>/`: archive notice, version/format handshake,
operator confirmation, lockdown kill switch, reload breaker and a guard on the macro command sinks.
Details and operator steps are in each pack's `ARCHIVED.md`. The gate is a safeguard for operators, not a
sandbox; the old 1.19.x packs (`TunnelScript`, `cmdTunnel-datapack`) only get the notice because the gate
needs macro and `return` support from newer versions.
