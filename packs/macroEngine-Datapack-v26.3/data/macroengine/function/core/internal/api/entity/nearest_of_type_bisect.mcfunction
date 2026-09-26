# macroengine:core/internal/api/entity/nearest_of_type_bisect [MACRO, INTERNAL]
# One step of an integer binary search for the smallest radius bucket that
# still contains a match of $(type) around $(player). Mirrors the
# fixed-iteration recursive style used by
# core/internal/systems/math/sqrt_step.
#
# Input (macro args via `with storage macroengine:_entity_tmp {}`):
#   $(type)   — entity type id string
#   $(player) — player name string
#   $(lo)     — lower bound in blocks; a hit is NOT guaranteed here
#   $(hi)     — upper bound in blocks; a hit IS guaranteed within this radius
#
# Recurses until the [lo, hi] bracket has collapsed to <= 1 block, then
# writes macroengine:output distance from the final hi. Each call first
# records hi as the current best distance so distance is always correct
# even if recursion is cut short.

$scoreboard players set $entity_bisect_lo macroengine.tmp $(lo)
$scoreboard players set $entity_bisect_hi macroengine.tmp $(hi)

execute store result storage macroengine:output distance int 1 run scoreboard players get $entity_bisect_hi macroengine.tmp

scoreboard players operation $entity_bisect_gap macroengine.tmp = $entity_bisect_hi macroengine.tmp
scoreboard players operation $entity_bisect_gap macroengine.tmp -= $entity_bisect_lo macroengine.tmp

# Bracket has collapsed to single-block precision — stop.
execute if score $entity_bisect_gap macroengine.tmp matches ..1 run return 0

scoreboard players operation $entity_bisect_mid macroengine.tmp = $entity_bisect_lo macroengine.tmp
scoreboard players operation $entity_bisect_mid macroengine.tmp += $entity_bisect_hi macroengine.tmp
scoreboard players set $entity_bisect_2 macroengine.tmp 2
scoreboard players operation $entity_bisect_mid macroengine.tmp /= $entity_bisect_2 macroengine.tmp

# Persist mid so the macro substitution below can read it back as $(mid).
execute store result storage macroengine:_entity_tmp mid int 1 run scoreboard players get $entity_bisect_mid macroengine.tmp

# If a match exists within `mid` blocks, the new hi is mid; otherwise the
# new lo is mid. Either way, recurse with the narrowed bracket.
$execute as @a[name=$(player),limit=1] at @s if entity @e[type=$(type),distance=..$(mid)] run function macroengine:core/internal/api/entity/nearest_of_type_bisect_lower with storage macroengine:_entity_tmp {}
$execute as @a[name=$(player),limit=1] at @s unless entity @e[type=$(type),distance=..$(mid)] run function macroengine:core/internal/api/entity/nearest_of_type_bisect_raise with storage macroengine:_entity_tmp {}
