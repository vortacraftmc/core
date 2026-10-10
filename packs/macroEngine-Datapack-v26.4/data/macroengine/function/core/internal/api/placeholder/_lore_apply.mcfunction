# macroengine:core/internal/api/placeholder/_lore_apply [INTERNAL]
# Appends the lines in _rest to the scratch item's lore, one resolved line per call.
execute unless data storage macroengine:placeholder _rest[0] run return 0
data modify storage macroengine:placeholder _cur set from storage macroengine:placeholder _rest[0]
item modify entity @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1] container.0 macroengine:placeholder/lore_line
data remove storage macroengine:placeholder _rest[0]
function macroengine:core/internal/api/placeholder/_lore_apply
