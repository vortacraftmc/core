# macroengine:api/cooldown/check [MACRO]
# Checks whether a named cooldown (set via macroengine:api/cooldown/set)
# has expired for the calling player.
#
# Input (macro args via `with storage macroengine:input {}`):
#   $(name) — cooldown name string. Normalized the same way as
#             macroengine:api/cooldown/set before lookup.
#
# Must be run `as` the target player (uses @s), e.g.:
#   execute as Steve run function macroengine:api/cooldown/check {name:"fireball"}
#
# Output → macroengine:output
#   found     -> 1b if run as a player, 0b otherwise
#   ready     -> 1b if the cooldown has expired or was never set
#   remaining -> ticks remaining (0 if ready)

data modify storage macroengine:output found set value 0b
data modify storage macroengine:output ready set value 0b
data modify storage macroengine:output remaining set value 0

execute unless entity @s[type=minecraft:player] run return 0
data modify storage macroengine:output found set value 1b

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

# Reset to 0 first: if no cooldown was ever set for this key, the "data get"
# below fails silently and would otherwise leave a stale score.
scoreboard players set #macroengine_cooldown_expiry macroengine.tmp 0
execute store result score #macroengine_cooldown_now macroengine.tmp run time query gametime
function macroengine:core/internal/api/cooldown/check_read with storage macroengine:_cooldown_tmp {}

execute if score #macroengine_cooldown_now macroengine.tmp >= #macroengine_cooldown_expiry macroengine.tmp run data modify storage macroengine:output ready set value 1b
execute unless score #macroengine_cooldown_now macroengine.tmp >= #macroengine_cooldown_expiry macroengine.tmp run scoreboard players operation #macroengine_cooldown_remaining macroengine.tmp = #macroengine_cooldown_expiry macroengine.tmp
execute unless score #macroengine_cooldown_now macroengine.tmp >= #macroengine_cooldown_expiry macroengine.tmp run scoreboard players operation #macroengine_cooldown_remaining macroengine.tmp -= #macroengine_cooldown_now macroengine.tmp
execute unless score #macroengine_cooldown_now macroengine.tmp >= #macroengine_cooldown_expiry macroengine.tmp store result storage macroengine:output remaining int 1 run scoreboard players get #macroengine_cooldown_remaining macroengine.tmp

# ── Debug log ─────────────────────────────────────────────────────────────
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cooldown_check","color":"aqua"},{"plain":true,"storage":"macroengine:_cooldown_tmp","nbt":"_name","color":"white"},{"translate":"macroengine.ui.arrow","color":"#555555"},{"plain":true,"storage":"macroengine:output","nbt":"ready","color":"green"}]

data remove storage macroengine:_cooldown_tmp _uuid
data remove storage macroengine:_cooldown_tmp _name
