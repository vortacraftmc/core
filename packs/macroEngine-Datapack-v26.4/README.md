# macroEngine (v26.4-snapshot-1)

**macroEngine** is a macro/module framework datapack for Minecraft Java Edition, providing a large library of reusable command-based systems (math, string, NBT, geo, permissions, UUID cache, hooks, rate limiting, and more) plus a multi-source text/value input system (dialogs, books, signs, lecterns, name tags, command block minecarts).

> Owner: [runtoolkit](https://github.com/runtoolkit)
> Minecraft: **26.4-snapshot-1** (`pack_format` / `min_format`–`max_format` **122**)
> 
> License: Unlicense
> 
> Namespace: `macroengine`
> 
> Maintainer: [vortacraftmc](https://github.com/vortacraftmc)

---

## Features

- **API layer** (`api/`) — stable public entry points: `cmd`, `cb` (callback queue), `color`, `dialog`, `gamerule`, `interaction`, `item`, `macro`, `perm`, `title`, `toggle`, `trigger`, `wand`
- **Systems layer** (`systems/`) — internal utility modules: `math`, `string`, `nbt`, `logic`, `geo`, `flag`, `hook`, `log`, `rate_limit`, `sound`, `uuid`, `color`
- **Input system** (`input/`) — capture player-provided values via writable book, sign, lectern, name tag, dialog, or command block minecart, with shared validation (`input/validate`) for int/float/bool/tag-safe strings
- **Toggle system** — per-module runtime enable/disable for `cb`, `perm`, `geo`, `wand`, `interaction`, `hook`, and `experimental` features
- **Rate limiting** — global, per-player, and per-channel request throttling
- **Hook system** — bind functions to fire on events such as block break, dimension change, and advancement grant
- **Item modifiers** (`item_modifier/`) — reusable `item_modifier` definitions for enchanting, glint, lore, tooltip, and rename operations
- **Advancement-driven triggers** (`advancement/`) — core, hidden, and system advancements used to drive internal logic and hooks
- **Experimental namespace** — gated behind `toggle/experimental`, for features not yet considered stable
- **Enchantments** (`enchantment/`) — `steady_hand`, `xp_thrift`, plus `momentum_surge` (movement speed on boots) and `overload_ward` (protection against macroEngine's own `overload`/`purge`/`sanctioned` damage types, grouped under `#macroengine:core` in `tags/damage_type/`)
- **Armor trim** (`trim_pattern/`, `trim_material/`) — custom `macroengine:circuit` pattern and `macroengine:overload` material (1.21.5+ registry shape: no `template_item`/`ingredient`, `override_armor_assets` only). Applied via any vanilla smithing template + the crafted trim ingot (`recipe/util/overload_trim_ingot.json`). Matching resource pack assets (overlay textures, color palette, `armor_trims.json` atlas extension via `replace:false`) ship in the companion resource pack
- **Trim processing** (`systems/trim/`) — example module that scans an entity's armor for the circuit+overload trim and fires a `macroengine:trim_matched` hook event per matching slot; `on_matched_example.mcfunction` shows a handler you can bind with `systems/hook/bind`. This fills the gap where the pack previously only had validation helpers (`input/validate/`) but no processing logic for the trim registries

---

## Requirements

- Minecraft Java Edition **26.4-snapshot-1**
- Datapack `min_format`/`max_format`: **122**

---

## Installation

1. Place the datapack folder in your world's `datapacks/` directory (or load it via a server-side pack source).
2. Run `/reload` or restart the server.
3. macroEngine initializes automatically via `#macroengine:events/on_load`.

To check the default tick configuration, see `data/macroengine/function/config/`.

---

## Usage

Most functionality is exposed through the `api/` namespace, e.g.:

```mcfunction
function macroengine:api/cmd/actionbar
function macroengine:api/dialog/show
function macroengine:api/perm/grant
function macroengine:api/wand/give
```

Internal systems under `systems/` are used by API functions and are not intended to be called directly by end users, though they remain accessible for advanced/custom integrations.

Example — scan a player for the circuit/overload trim and react to matches:

```mcfunction
data modify storage macroengine:input event set value "macroengine:trim_matched"
data modify storage macroengine:input func set value "macroengine:systems/trim/on_matched_example"
function macroengine:systems/hook/bind with storage macroengine:input {]

execute as @a run function macroengine:systems/trim/scan
```

---

## Notes

- This is the 26.4-snapshot-1 build of macroEngine (folder retains its original `v26.3` name), part of the `runtoolkit/suite` monorepo (`packs/macroEngine-Datapack-v26.3`).
- Experimental features are opt-in via `api/toggle/experimental/true` and are not guaranteed stable between versions.

---

## License

Unlicense — see the repository [LICENSE](https://github.com/vortacraftmc/core/blob/main/LICENSE). (This repo is archived.)
