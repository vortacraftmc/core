# macroengine:core/internal/api/placeholder/_plain_resolve [INTERNAL]
# Resolves _rest[0] on the scratch item and leaves its text in _piece (unset when it has none).
data modify storage macroengine:placeholder _src set from storage macroengine:placeholder _rest[0]
item modify entity @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1] container.0 macroengine:placeholder/name
data modify storage macroengine:placeholder _piece set from entity @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1] Items[{Slot:0b}].components."minecraft:custom_name".text
