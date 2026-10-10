# macroengine:core/internal/api/placeholder/_lore_loop [INTERNAL]
# Walks _rest: a %nl% component ends the current lore line, anything else joins it.
execute unless data storage macroengine:placeholder _rest[0] run return run function macroengine:core/internal/api/placeholder/_lore_end
scoreboard players set #ph_nl macroengine.tmp 0
execute if data storage macroengine:placeholder _rest[0].text run function macroengine:core/internal/api/placeholder/_lore_is_nl
execute if score #ph_nl macroengine.tmp matches 1 run function macroengine:core/internal/api/placeholder/_lore_flush
execute if score #ph_nl macroengine.tmp matches 0 run data modify storage macroengine:placeholder _line append from storage macroengine:placeholder _rest[0]
data remove storage macroengine:placeholder _rest[0]
function macroengine:core/internal/api/placeholder/_lore_loop
