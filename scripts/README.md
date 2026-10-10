# scripts/

Helper tooling for this monorepo. `NOTICE.md` treats everything here as
**lower trust by default** - read a script before running it, especially
`backup-org.sh`, which handles a token with org-wide read access.

There was previously no index for this directory: six scripts and three
self-contained tools sat side by side with nothing saying what any of them did,
which is why three one-off fixers from a single audit session were still
checked in and looked like part of the toolchain. They were removed; this file
exists so the next reader does not have to reconstruct the difference.

## Repository tooling

| Script | Run by | What it does |
|---|---|---|
| [`lint_datapacks.sh`](lint_datapacks.sh) | `build.yml`, step **Lint datapacks** — enforced | Installs Mecha (pinned, `MECHA_VERSION`) and validates `.mcfunction` **command syntax** for every pack not in `IGNORE_PATHS`. Propagates Mecha's exit status; `LINT_WARN_ONLY=1` makes one run advisory. Does **not** load packs or resolve references. |
| [`audit_repo.py`](audit_repo.py) | by hand | Working-tree consistency audit: `pack.mcmeta` shape and format ranges, plural/singular data folders, load/tick references, merge-manifest coherence, broken Markdown links, dangling workflow references, CI shape, and commit-message quality. Also flags invalid NBT paths (`[N]{}`, which Mecha and the game both reject), unresolvable load/tick tag values, and stale branches. `--json` / `--format github` for machine output, `--fail-on <severity>` to use it as a CI gate (exit 0 by default), `--min-severity`, `--only`/`--skip` to filter, `--fix [--dry-run]` for the safe file fixes; deleting remote branches additionally needs `--delete-stale-branches` and only ever touches fully merged, unprotected branches. |
| [`audit_full.py`](audit_full.py) | by hand | Superset of the above that also queries GitHub: org plan and 2FA policy, repository settings and topics, workflow/action pinning, and Dependabot/secret-scanning state. Calls `audit_repo.py` for the local half. Needs a token. |
| [`check_archive.py`](check_archive.py) | by hand (mirrors `./gradlew checkArchive`) | Validates `archived/archive.json` against its schema, and that nothing registered as archived is still under `packs/` or still in `merge-manifest.json`. Stdlib only, no network. |
| [`fix_text_components.py`](fix_text_components.py) | by hand | Rewrites `{"storage":…,"nbt":…}` text components so they set `interpret` and `plain` explicitly. On 26.1+ a missing pair makes a string render **with its quotes** and a number or boolean render with vanilla colouring. Referenced from `packs/macroEngine-Datapack-v26.4/README.md`. |
| [`backup-org.sh`](backup-org.sh) | `backup-org.yml`, or by hand | Full organization backup: bare git clones, wikis, issues/PRs/releases, Actions/Dependabot/security metadata, team membership and repo access, topics and languages, org settings — then sanitises credentials out of the metadata, archives it (optionally encrypted) and verifies the result. |

```bash
bash scripts/backup-org.sh --help          # full flag list
bash scripts/backup-org.sh --dry-run       # rehearsal; writes nothing but the log
python3 scripts/audit_repo.py              # local consistency report
```

## Self-contained tools

Each has its own README, licence and dependency manifest, and is versioned
independently of the repository tooling above.

| Directory | What it is | Manifest |
|---|---|---|
| [`dp-depman/`](dp-depman/) | Dependency resolver and editor for datapacks that declare a `datapack_depends.json`. | `datapack_depends.lock` |
| [`dpgen/`](dpgen/) | Generates a datapack from a YAML description, so generated files do not have to be checked in. | `package.json` |
| [`gui_generator/`](gui_generator/) | `guigenmc` — generates the `guikit` in-game GUI datapack from a menu spec; ships a browser UI and a test suite. | `pyproject.toml`, `requirements.txt` |

`dpgen` and `gui_generator` are the two directories Dependabot watches
(`.github/dependabot.yml`); `build.yml` runs the `guigenmc` tests on Python 3.9
and 3.12.

## Removed from here

`apply_audit_fixes.py`, `fix_macro_lines.py`, `datapack_risk_scan.py` and
`datapack_lock/check_lock.py` were deleted on 2026-10-08. The first two were
one-off fixers from a single audit session whose changes were already
committed; `check_lock.py` implemented a lock that nothing invoked, against a
workflow that never existed. If you are looking for one of them, that is why it
is gone — see the commit that removed them for the evidence.
