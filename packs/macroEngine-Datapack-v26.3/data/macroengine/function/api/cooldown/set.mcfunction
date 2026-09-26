# macroengine:api/cooldown/set [MACRO]
# Starts a named cooldown for a player, independent of any item — useful
# for ability/skill cooldowns that aren't tied to a specific item stack.
# Stores an absolute expiry tick in macroengine:engine, keyed by the
# player's UUID and the cooldown name, so it survives item changes,
# death, and relog.
#
# Input (macro args via `with storage macroengine:input {}`):
#   $(name)  — cooldown name string, e.g. "fireball". Normalized the same
#              way as macroengine:api/gamerule/set (spaces → underscores,
#              lowercased) before being used as a storage key.
#   $(ticks) — duration in ticks from now (20 ticks = 1 second)
#
# Must be run `as` the target player (uses @s), e.g.:
#   execute as Steve run function macroengine:api/cooldown/set {name:"fireball",ticks:60}
#
# RETURN: 1 on success, 0 if not run as a player.

execute unless entity @s[type=minecraft:player] run return 0

function macroengine:systems/uuid/from_entity
data modify storage macroengine:_cooldown_tmp _uuid set from storage macroengine:input value

# ── Normalize cooldown name: spaces → underscores, then lowercase ───────────
data modify storage macroengine:core/internal/string/input replace.String set from storage macroengine:input name
data modify storage macroengine:core/internal/string/input replace.Find set value " "
data modify storage macroengine:core/internal/string/input replace.Replace set value "_"
function macroengine:core/internal/string/util/replace
data modify storage macroengine:core/internal/string/input to_lowercase.String set from storage macroengine:core/internal/string/output replace
data remove storage macroengine:core/internal/string/input replace
function macroengine:core/internal/string/util/to_lowercase/fast
data modify storage macroengine:_cooldown_tmp _name set from storage macroengine:core/internal/string/output to_lowercase

execute store result score #macroengine_cooldown_now macroengine.tmp run time query gametime
$scoreboard players add #macroengine_cooldown_now macroengine.tmp $(ticks)
execute store result storage macroengine:_cooldown_tmp _expiry int 1 run scoreboard players get #macroengine_cooldown_now macroengine.tmp

function macroengine:core/internal/api/cooldown/set_write with storage macroengine:_cooldown_tmp {}

# ── Debug log ─────────────────────────────────────────────────────────────
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cooldown_set","color":"aqua"},{"plain":true,"storage":"macroengine:_cooldown_tmp","nbt":"_name","color":"white"}]

data remove storage macroengine:_cooldown_tmp _uuid
data remove storage macroengine:_cooldown_tmp _name
data remove storage macroengine:_cooldown_tmp _expiry
