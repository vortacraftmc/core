# Moving from small "data API" style datapacks

macroEngine covers the helpers those packs usually provide, with the same macro-call style:

| Typical need | macroEngine |
|---|---|
| read / write / append / merge / remove NBT by `storage` + `path` | `api/data/get`, `set`, `set_default`, `append`, `merge`, `remove`, `exists`, `count`, `copy`, `add` (counters), `toggle` (flags), `pop` / `shift` (stack / queue) |
| placeholders in chat, titles, action bars | `api/placeholder/*`, `api/title/*_p` |
| run a command on a player / as a player | `api/cmd/*` |
| scheduled and delayed callbacks | `api/cb/*` |
| permissions, hooks, rate limits, RNG, math, string/text helpers | `api/perm`, `systems/*` |

Notes:

* This is a **concept mapping, not a drop-in shim**: function names differ from other packs.
  Check the pack you are leaving and map the calls one by one.
* `api/data/*` passes values through `macroengine:data value`, so no SNBT needs escaping:

```mcfunction
data modify storage macroengine:data value set value {hp:20,name:"Steve"}
function macroengine:api/data/set {storage:"mypack:data",path:"players.steve"}
function macroengine:api/data/get {storage:"mypack:data",path:"players.steve.hp"}
# -> macroengine:data result
```

* macroEngine has no load gate and never needs `op`, `allowCommands` or `level.dat` edits.
  Access control belongs to the server layer (Fabric), not to the datapack.
