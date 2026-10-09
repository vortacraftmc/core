# Data module (`api/data`)

Small helpers over any command storage. Every function takes `storage` (e.g. `"mypack:data"`) and
`path` (e.g. `"players.steve.kills"`) as **macro arguments**. Values travel through
`macroengine:data value` / `macroengine:data result`, so no SNBT ever needs escaping.

## Functions

| Function | Macro args | Value in | Result |
|---|---|---|---|
| `get` | `storage`, `path` | | `macroengine:data result`; returns 1 if the path exists, else 0 (result removed) |
| `set` | `storage`, `path` | `value` | overwrites the path |
| `set_default` | `storage`, `path` | `value` | writes only if the path is missing; returns 1 if it wrote, 0 if it existed |
| `append` | `storage`, `path` | `value` | appends to the list |
| `merge` | `storage`, `path` | `value` | merges a compound |
| `remove` | `storage`, `path` | | removes the path |
| `exists` | `storage`, `path` | | returns 1 / 0 |
| `count` | `storage`, `path` | | list length, string length or compound key count (0 if missing) |
| `copy` | `from`, `from_path`, `to`, `to_path` | | copies one value to another place |
| `add` | `storage`, `path`, `by` | | adds `by` (may be negative) to an int; a missing path counts as 0; returns the new value |
| `toggle` | `storage`, `path` | | flips a 0b/1b flag (missing becomes 1b); returns the new value |
| `pop` | `storage`, `path` | | removes the last list element into `result`; returns 1 if one was removed |
| `shift` | `storage`, `path` | | removes the first list element into `result` (queue); returns 1 if one was removed |

## Using the return value

`execute if function` does **not** accept macro arguments, so a macro function cannot be used as a
condition directly. Capture the return value with `execute store result` and test the score:

```mcfunction
execute store result score #r mypack.tmp run function macroengine:api/data/pop {storage:"mypack:data",path:"stack"}
execute if score #r mypack.tmp matches 1 run say popped
execute if score #r mypack.tmp matches 0 run say empty
```

Use your own objective (`mypack.tmp` here); `macroengine.tmp` is written by macroEngine's internals.

## Examples

```mcfunction
# initialise once, never overwrite live data
data modify storage macroengine:data value set value {kills:0,coins:100}
function macroengine:api/data/set_default {storage:"mypack:data",path:"players.steve"}

# counters and flags
function macroengine:api/data/add {storage:"mypack:data",path:"players.steve.kills",by:1}
function macroengine:api/data/toggle {storage:"mypack:data",path:"settings.pvp"}

# stack (pop) and queue (shift)
data modify storage mypack:data stack set value ["a","b","c"]
function macroengine:api/data/pop {storage:"mypack:data",path:"stack"}     # result = "c"
function macroengine:api/data/shift {storage:"mypack:data",path:"stack"}   # result = "a"

# read
function macroengine:api/data/get {storage:"mypack:data",path:"players.steve.coins"}
tellraw @s {"storage":"macroengine:data","nbt":"result"}
```

## Notes

* Arguments are developer input, like every macro API in the pack. Do not pass player-written
  text as `storage` or `path`.
* `pop` uses the negative index `[-1]`; verify it on your target version.
* `add` reads the value as an integer, so a float is truncated.
