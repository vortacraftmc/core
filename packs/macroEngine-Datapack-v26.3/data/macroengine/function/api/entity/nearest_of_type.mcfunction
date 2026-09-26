# macroengine:api/entity/nearest_of_type [MACRO]
# Finds the nearest entity of a given type within range of a named player
# and reports its UUID and an approximate integer distance. Wraps the
# vanilla @e[type=...,sort=nearest] selector so callers don't need to
# hand-roll a target selector + UUID lookup each time.
#
# Input (macro args via `with storage macroengine:input {}`):
#   $(player) — player name string, e.g. "Steve"
#   $(type)   — entity type id string, e.g. "minecraft:zombie"
#   $(range)  — search radius in blocks, e.g. 16
#
# EXAMPLE:
#   data modify storage macroengine:input player set value "Steve"
#   data modify storage macroengine:input type set value "minecraft:zombie"
#   data modify storage macroengine:input range set value 16
#   function macroengine:api/entity/nearest_of_type with storage macroengine:input {}
#
# Output → macroengine:output
#   found     -> 1b if the player exists, 0b otherwise
#   hit       -> 1b if a matching entity was found in range
#   distance  -> integer block distance, rounded up to the nearest whole
#                block (0 if no hit). Computed by a binary search over the
#                vanilla `distance=..N` selector bucket, since mcfunction
#                has no native sqrt on raw coordinates.
#   uuid      -> string UUID of the nearest match ("" if no hit)

data modify storage macroengine:output found set value 0b
data modify storage macroengine:output hit set value 0b
data modify storage macroengine:output distance set value 0
data modify storage macroengine:output uuid set value ""

$execute unless entity @a[name=$(player),limit=1] run return 0
data modify storage macroengine:output found set value 1b

$execute as @a[name=$(player),limit=1] at @s unless entity @e[type=$(type),distance=..$(range),limit=1] run return 0
data modify storage macroengine:output hit set value 1b

# ── Capture the match's UUID from the caller's position ─────────────────────
$execute as @a[name=$(player),limit=1] at @s as @e[type=$(type),distance=..$(range),sort=nearest,limit=1] run function macroengine:core/internal/api/entity/nearest_of_type_uuid

# ── Binary search 0..range for the smallest bucket that still contains a hit
$data modify storage macroengine:_entity_tmp type set value "$(type)"
$data modify storage macroengine:_entity_tmp player set value "$(player)"
data modify storage macroengine:_entity_tmp lo set value 0
$data modify storage macroengine:_entity_tmp hi set value $(range)
function macroengine:core/internal/api/entity/nearest_of_type_bisect with storage macroengine:_entity_tmp {}

# ── Debug log ─────────────────────────────────────────────────────────────
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.entity_nearest","color":"aqua"},{"text":"$(type)","color":"white"},{"translate":"macroengine.ui.arrow","color":"#555555"},{"plain":true,"storage":"macroengine:output","nbt":"hit","color":"green"}]

data remove storage macroengine:_entity_tmp type
data remove storage macroengine:_entity_tmp player
data remove storage macroengine:_entity_tmp lo
data remove storage macroengine:_entity_tmp hi
