# macroengine:core/internal/api/placeholder/_derive [INTERNAL]
# Builds resolved / custom_name / lore / string / string_ok from `out` (see api/placeholder/parse).
# Everything is resolved by the server through a scratch item: `item modify` runs the
# set_name / set_lore functions with the executor as "this", which resolves selectors,
# scores and NBT components; the result is read back from the item.

# defaults, so every key exists after any parse
data modify storage macroengine:placeholder resolved set value {text:""}
data modify storage macroengine:placeholder custom_name set value {text:"",italic:false}
data modify storage macroengine:placeholder lore set value []
data modify storage macroengine:placeholder lore_live set value []
data modify storage macroengine:placeholder string set value ""
data modify storage macroengine:placeholder string_ok set value 1b
execute unless data storage macroengine:placeholder out[0] run return 0

summon minecraft:chest_minecart ~ ~ ~ {Invisible:1b,NoGravity:1b,Silent:1b,Tags:["macroengine.ph_scratch"]}
item replace entity @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1] container.0 with minecraft:stone

# the whole text as one resolved component (a bare root makes it a single compound)
data modify storage macroengine:placeholder _src set from storage macroengine:placeholder out
data modify storage macroengine:placeholder _src prepend value {text:""}
item modify entity @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1] container.0 macroengine:placeholder/name
data modify storage macroengine:placeholder resolved set from entity @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1] Items[{Slot:0b}].components."minecraft:custom_name"
data modify storage macroengine:placeholder custom_name set from storage macroengine:placeholder resolved
execute unless data storage macroengine:placeholder custom_name.italic run data modify storage macroengine:placeholder custom_name.italic set value false

# lore: cut `out` into lines, then let the server resolve them one at a time
data modify storage macroengine:placeholder _line set value []
data modify storage macroengine:placeholder _rest set from storage macroengine:placeholder out
function macroengine:core/internal/api/placeholder/_lore_loop
item modify entity @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1] container.0 macroengine:lore_clear
data modify storage macroengine:placeholder _rest set from storage macroengine:placeholder lore_live
function macroengine:core/internal/api/placeholder/_lore_apply
execute if data entity @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1] Items[{Slot:0b}].components."minecraft:lore" run data modify storage macroengine:placeholder lore set from entity @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1] Items[{Slot:0b}].components."minecraft:lore"

# plain string
function macroengine:core/internal/api/placeholder/_plain

kill @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1]
data remove storage macroengine:placeholder _src
data remove storage macroengine:placeholder _cur
data remove storage macroengine:placeholder _rest
data remove storage macroengine:placeholder _line
data remove storage macroengine:placeholder lore_live
