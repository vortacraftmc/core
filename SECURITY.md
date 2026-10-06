# Security Policy

## Status: maintenance paused

As of 2026-10-04 the maintainer expects to be inactive on GitHub until at least 2027–2028. Until then:

- Security reports (private advisories and issues) may not be read or answered, and no fixes, advisories or releases should be expected. This **overrides** the response targets further down.
- No version of anything in this repository is supported. Treat all of it as unpatched.
- You may still report a problem privately; it will be handled if and when maintenance resumes. If it matters to you now, fork the project (Unlicense) and patch your copy.
- Everything under `archived/` stays reference-only: do not deploy it on a live server without review.

## Reporting a vulnerability

If you find a security issue in any project under this repository (Fabric
mods, datapacks, or helper scripts), please report it privately rather than
opening a public issue.

- Preferred: use [GitHub's private vulnerability reporting](https://github.com/vortacraftmc/core/security/advisories/new)
  for this repo.
- If that's not available to you, open an issue with minimal detail
  (e.g. "possible command injection in X, details sent privately") and we'll
  follow up for the specifics.

Do not include working exploit code or live payloads in public issues or pull requests (see "Prohibited content and practices" below).

Please include:
- Affected project/path (e.g. `packs/RTWrapper`, `mods/...`)
- Steps to reproduce, or a minimal example
- Impact (what an attacker could actually do)
- Minecraft/Fabric/Loom version, if relevant

We'll acknowledge reports as soon as we can and aim to have a fix or
mitigation out within a reasonable timeframe depending on severity. Low-risk
findings in archived/frozen projects (see below) may not get a fix, but will
be documented.

## Scope

This repo consolidates multiple projects with different security postures:

| Area | Status |
|---|---|
| `mods/` | Fabric mods. Maintenance paused (see Status above). Compiled, type-safe. |
| `packs/` | Only the macroEngine resource pack. All datapacks are archived and frozen (see `archived/`). |
| `scripts/` | Helper tooling. Treat as lower trust; review before running. |
| `examples/` | Templates and sample code. Not intended for production use. |
| `archived/` | Reserved for no-longer-maintained projects, kept for reference only — do not deploy on a live server without review. Tracked in `archived/archive.json`; see `archived/README.md`. |

Datapacks and Fabric mods carry different security postures by nature; where
practical, security-sensitive logic lives in a Fabric mod rather than a
datapack. Projects that have stopped receiving updates are frozen and marked
archived rather than left in an inconsistent, partially-hardened state.

## Prohibited content and practices

The following are not accepted in this repository (code, issues, pull requests, documentation, examples, or releases) and are not recommended by any project in it. This applies **even when the stated intent is benign** (testing, education, "admin convenience", research).

### 1. Exploits for Minecraft or its ecosystem

- No exploit code, proof-of-concept payloads, or step-by-step exploitation guides for zero-day or unpatched vulnerabilities in Minecraft (client or server), Fabric, Forge/NeoForge, Paper/Spigot, other mod loaders, mods, plugins, or their dependencies.
- No weaponized use of known vulnerabilities such as Log4Shell (CVE-2021-44228) or similar injection and deserialization flaws. Describing a vulnerability class at a high level so that others can defend against it is fine; shipping a working chain is not.
- Vulnerabilities in third-party software should be reported to the vendor or upstream maintainer (for Minecraft itself, to Mojang/Microsoft) and not published here before a fix exists.

### 2. Prompt injection and AI-targeted payloads

- No payloads, text, or file content designed to manipulate AI assistants, code reviewers, or automated tooling that reads this repository (prompt injection), including instructions hidden in comments, metadata, item names, books, signs, or datapack/mod files.
- Reports about prompt injection weaknesses in a project's own AI-facing features are welcome through the private reporting channel above. Do not include working payloads in public issues.

### 3. Running operating-system commands from datapacks

- Datapacks cannot run PowerShell, Bash, `cmd`, or any other OS command on their own. Any method that claims to do so depends on an exploit, on a vulnerable, misconfigured or malicious mod or plugin, or on an external tool that executes console or chat output.
- We do not publish, accept, or recommend such methods, including "harmless" or "admin-only" variants, wrappers, bridges, or file-watcher setups that turn in-game commands, storage, signs, books, or command output into shell execution.
- Projects here must not depend on a component that provides in-game shell or file-system execution.

### 4. RCON

- **Malicious use:** RCON must never be used to gain, keep, or escalate unauthorized access to a server, and no code or documentation in this repo may help with that (for example brute-forcing, scanning for exposed RCON ports, or password guessing).
- **Legitimate use is discouraged and restricted.** RCON is not recommended by any project in this repo. A project may support it only if all of the following hold:
  - RCON is disabled by default (`enable-rcon=false`) and documented as optional.
  - It is bound to `127.0.0.1` or a firewalled, trusted network and is never exposed to the public internet.
  - A strong, unique `rcon.password` is used and is supplied through a secret store or environment variable, never committed to the repository or printed in logs.
  - It is never used as a bridge from a datapack, chat, or player input to a shell or the file system.
  - It is limited to the minimum set of commands the project needs.
- RCON-related security findings should be reported privately.

### 5. Enforcement

- Content that violates this section will be removed, and the related issue or pull request closed without a fix or discussion of exploit details.
- Repeated or deliberate violations may result in a ban from the repository.
- Archived and frozen projects are covered as well: their code is kept for reference only and is not an endorsement of any method listed above.

## Supported versions

Only the versions/branches actively referenced in each subproject's own
README receive security fixes. Archived projects (see table above) are
provided as-is.

## Third-party forks and converters

If you're using a fork, a "datapack to mod converter" output, or any
derivative of a project in this repo, verify it against the original source
here before trusting it — converted or forked artifacts are not covered by
this policy and may not reflect the same security posture.