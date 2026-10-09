# macroengine:core/internal/api/placeholder/_try_score [INTERNAL]
# Handles %score:<objective>%. The "score:" prefix is split off first so the
# remaining objective name can be validated like any other name.
data modify storage macroengine:placeholder pre set string storage macroengine:placeholder name 0 6
execute store success score #ph_diff macroengine.tmp run data modify storage macroengine:placeholder pre set value "score:"
execute if score #ph_diff macroengine.tmp matches 1 run return 0
data modify storage macroengine:placeholder obj set string storage macroengine:placeholder name 6
data modify storage macroengine:text s set from storage macroengine:placeholder obj
execute store result score #ph_ok macroengine.tmp run function macroengine:core/internal/api/placeholder/_validate_name
execute if score #ph_ok macroengine.tmp matches 1 run function macroengine:core/internal/api/placeholder/_score_build with storage macroengine:placeholder
