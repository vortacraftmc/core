# Placeholder module (`api/placeholder`)

Resolves `%name%` tokens in text into a **text component list**, so values such as the
player name, scores and storage data are resolved by Minecraft's own text engine.

## Why components instead of string replacement

* The input text is **never substituted into a command line or a JSON string**. It is
  split with `core/internal/text` and copied with `data modify ... set from`. Quotes,
  backslashes and braces in chat, signs or books cannot break out of anything.
* Values stay live (`%score:coins%` is a real score component, not a snapshot).
* Colours, hover/click events and any other component can be a placeholder.

No operator, `level.dat` edit or load confirmation is needed: there is no gate.

## Usage

```mcfunction
# 1. built-ins work out of the box
data modify storage macroengine:placeholder in set value "Hi %player%! You have %score:coins% coins."
function macroengine:api/placeholder/send          # chat, for @s
function macroengine:api/placeholder/send_all      # chat, resolved per recipient
function macroengine:api/placeholder/actionbar     # action bar, for @s
function macroengine:api/placeholder/actionbar_all # action bar, resolved per recipient
function macroengine:api/placeholder/send_to {player:"Steve"}

# 2. get the component list yourself
function macroengine:api/placeholder/parse
tellraw @a {"storage":"macroengine:placeholder","nbt":"out","interpret":true}
```

## Syntax

| Token | Meaning |
|---|---|
| `%name%` | registered placeholder |
| `%score:<objective>%` | scoreboard value of the executor |
| `%%` | a literal `%` |
| anything else | left untouched (`50% of 20% more` stays as written) |

Built-ins: `%player%`, `%name%` (executor name), `%nl%` (line break), `%percent%`, and live
values of the executor: `%health%`, `%food%`, `%xp_level%`, `%dimension%`.

Placeholders resolve for the **executor** (`@s`). To address someone else use
`execute as <player> run function ...`; `send_all`/`broadcast_p` do this per recipient.

## Registering your own

| Function | Macro args | Result |
|---|---|---|
| `register_text` | `name`, `value` | fixed text (no quote or backslash in `value`) |
| `register_score` | `name`, `holder`, `objective` | scoreboard value (`holder` may be `@s` or `#fake`) |
| `register_storage` | `name`, `storage`, `path` | NBT value, rendered plain |
| `register_selector` | `name`, `selector` | entity/player name |
| `register_component` | `name` (+ `in.component` in storage) | any text component; a plain string (any characters) or an array of strings/components works too |
| `register_alias` | `alias`, `target` | `%alias%` behaves like the registered `%target%` |
| `unregister` / `exists` / `list` | `name` | manage the registry |
| `reset` | none | drop everything, restore the built-ins |

```mcfunction
function macroengine:api/placeholder/register_score {name:"kills",holder:"@s",objective:"kills"}
data modify storage macroengine:placeholder in.component set value {text:"VIP",color:"gold",bold:true}
function macroengine:api/placeholder/register_component {name:"rank"}
```

### Value types

A registered value (`reg.<name>` in `macroengine:placeholder`) can be:

| Stored as | Shown as |
|---|---|
| compound (text component) | the component itself |
| string | a plain text component |
| array | its elements one after another; each element may be a string, a component or another array, and none of them styles the others |

Strings and arrays are wrapped into a single component when the placeholder is resolved, so
`out` only ever contains components and raw `data modify ... reg.<name> set value "text"` or `[...]` works without
any `register_*` call. Empty strings and arrays show nothing. Numbers are not supported as stored values. The text of a
registered value is not parsed for `%placeholders%` again.

```mcfunction
# a string with quotes and braces: no escaping problems, it comes from storage
data modify storage macroengine:placeholder in.component set value "Say \"hi\" to {everyone}"
function macroengine:api/placeholder/register_component {name:"greeting"}

# an array of parts shown one after another
data modify storage macroengine:placeholder in.component set value [{text:"[",color:"gray"},{selector:"@s",color:"white"},{text:"]",color:"gray"}]
function macroengine:api/placeholder/register_component {name:"tag"}
```

`register_component` returns nothing special; there is no separate string or array function because
the value type is detected when the placeholder is resolved.

Registration arguments are developer input (like every other macro API in this pack).
Only *text being parsed* is treated as untrusted. Placeholder names are validated
against quotes, backslashes and the `deny_name` table before they reach a macro.

## Outputs

Every `parse` (and so `send`, `give`, ...) leaves the result in the same four forms, both in
`macroengine:placeholder` and mirrored to `macroengine:output placeholder.<key>`:

| Key | Form | Use it for |
|---|---|---|
| `out` | list of text components | `tellraw`, `title`, `{"storage":...,"nbt":"out","interpret":true}` |
| `string` | the same list written out as an SNBT **string** | storing, comparing, or `$tellraw @s $(string)` through a macro |
| `custom_name` | one component, `italic:false` on its root | `custom_name=` |
| `lore` | list of lines, split at every `%nl%`, each `italic:false` on its root | `lore=` |

A root that sets `italic` itself keeps it. A trailing `%nl%` adds no empty line; two in a row make one.
`string` is the component as written, not resolved text: `%player%` stays `{selector:"@s"}` in it, because
Minecraft only turns selectors, scores and NBT into words when a component is displayed.

```mcfunction
data modify storage macroengine:placeholder in set value "%player%'s sword%nl%Kills: %score:kills%"
function macroengine:api/placeholder/parse

# straight into an item, through a macro that reads the storage
function macroengine:api/placeholder/give {item:"minecraft:iron_sword"}

# or your own command: $(custom_name) and $(lore) are written out as SNBT
# (helper.mcfunction)  $item replace entity @s weapon.mainhand with minecraft:stick[custom_name=$(custom_name),lore=$(lore)]
function mypack:helper with storage macroengine:placeholder

# the string form through a macro
# (show.mcfunction)  $tellraw @s $(string)
function mypack:show with storage macroengine:placeholder
```

## Checking results

`parse` returns the number of components it produced, and `exists` returns 1 or 0. `execute if function`
cannot pass macro arguments, so store the return value instead:

```mcfunction
execute store result score #r mypack.tmp run function macroengine:api/placeholder/exists {name:"rank"}
execute if score #r mypack.tmp matches 1 run say registered
```

## Output storage

Every `parse` call (and so `send`, `send_to`, `actionbar`, ...) also copies its data to
`macroengine:output`:

| Path | Content |
|---|---|
| `placeholder.in` | the input string; absent when there was no input |
| `placeholder.out` | the resolved component list (`[]` when there was no input) |
| `placeholder.reg` | snapshot of all registered placeholders; absent when none exist |

```mcfunction
data modify storage macroengine:placeholder in set value "Hi %player%"
function macroengine:api/placeholder/parse
data get storage macroengine:output placeholder.out
```

## Title and action bar

[title.md](title.md) documents the title functions. `api/title/show_p`, `show_to_p`, `broadcast_p`, `show_team_p {team}`, `show_tag_p {tag}`,
`show_area_p {radius}`, `actionbar_p`, `actionbar_all_p` and `actionbar_tag_p {tag}` take
their text from `macroengine:title in` and support the same placeholders; see the
header of each function.

## Limits

* `%score:<objective>%` is the only dynamic token; other `%a:b%` forms are kept as text.
* Placeholder names cannot contain characters in the `deny_name` table (space, `:`, `{}[]()`, etc.).
* Selectors and scores resolve when the component is displayed, which is why
  there is deliberately no "flatten to plain string" function.
