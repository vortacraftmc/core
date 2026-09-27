## Localization & Required Resource Pack

**The companion resource pack is REQUIRED.**

All user-facing `tellraw` / title messages use Minecraft translation keys under the `macroengine.*` namespace.
Language files are provided in the resource pack:

- `assets/macroengine/lang/en_us.json` — English
- `assets/macroengine/lang/tr_tr.json` — Turkish (Türkçe)

Without the resource pack:
- Messages fall back to raw translation keys or English defaults where `fallback` is used
- Custom sounds and death messages will not work
- Players receive a recurring warning on join

Server operators should set in `server.properties`:
```
require-resource-pack=true
resource-pack=<url to macroEngine-Resourcepack-v26.3-i18n.zip>
resource-pack-prompt=macroEngine resource pack is required
```

Or distribute the resource pack as a world/server resource pack.

---

# macroEngine (v26.3)

> ⚠️ **UNSUPPORTED.** This datapack is archived and no longer maintained. Development has moved to [macroEngine v26.4](https://github.com/vortacraftmc/core/tree/main/packs/macroEngine-Datapack-v26.4), its successor. No new features or fixes are planned. (v26.4 is a separate, still-supported pack.)
>
> On every `/reload` the pack prints an unsupported warning, and the internal engine (`macro:input`/`macro:output`/`macro:engine`) will **not** initialize unless you explicitly opt in with `/data modify storage macroengine:engine config.allow_unsupported_load set value 1b`. Static content (recipes, loot tables, advancements, predicates, item modifiers, enchantments) is unaffected either way. See `core/internal/load/unsupported_gate.mcfunction`.

**macroEngine** is a macro/module framework datapack for Minecraft Java Edition, providing a large library of reusable command-based systems (math, string, NBT, geo, permissions, UUID cache, hooks, rate limiting, and more) plus a multi-source text/value input system (dialogs, books, signs, lecterns, name tags, command block minecarts).

> Owner: [vortacraftmc](https://github.com/vortacraftmc)
> Minecraft: **26.3** (`pack_format` / `min_format`–`max_format` **121**)
> License: Unlicense
> Namespace: `macroengine`

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

---

## Requirements

- Minecraft Java Edition **26.3**
- Datapack `min_format`/`max_format`: **122**

---

## Installation

1. Place the datapack folder in your world's `datapacks/` directory (or load it via a server-side pack source).
2. Run `/reload` or restart the server.
3. macroEngine initializes automatically via `#macroengine:events/on_load`.

To manually check load state or configuration, see `data/macroengine/function/config/` and `data/macroengine/function/debug/`.

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

---

## Notes

- This is the 26.3 line of macroEngine, part of the `vortacraftmc/core` monorepo (`packs/macroEngine-Datapack-v26.3`).
- Experimental features are opt-in via `api/toggle/experimental/true` and are not guaranteed stable between versions.

---

## License

Unlicense — see the repository [LICENSE](https://github.com/vortacraftmc/core/blob/main/LICENSE).
