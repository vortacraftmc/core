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

# item_modifier/placeholder/name.json and lore_line.json resolve @s against
# "entity":"this", which during `item modify entity <target>` is the scratch
# chest_minecart, not the player out was built for. Rebind those "@s"
# references onto the actual caller before baking anything from `out`, so
# %player%, %health%, %food%, %xp_level%, %dimension%, %name% and any
# register_selector/register_score placeholder resolve correctly instead of
# resolving against the minecart (empty/wrong values).
# NOTE: every rebind below is guarded by `execute if data ...[filter]`. A filtered
# path (`list[{k:v}]`) on `data modify ... set` CREATES a new `{k:v}` element when
# nothing matches, which injected bogus {entity:..}/{score:..} parts into the text
# ("Failed to parse component"). Do not drop the guards.
tag @s add macroengine.ph_caller
data modify storage macroengine:placeholder _resolved_src set from storage macroengine:placeholder out
execute if data storage macroengine:placeholder _resolved_src[{entity:"@s"}] run data modify storage macroengine:placeholder _resolved_src[{entity:"@s"}].entity set value "@e[tag=macroengine.ph_caller,distance=..2,limit=1]"
execute if data storage macroengine:placeholder _resolved_src[{selector:"@s"}] run data modify storage macroengine:placeholder _resolved_src[{selector:"@s"}].selector set value "@e[tag=macroengine.ph_caller,distance=..2,limit=1]"
execute if data storage macroengine:placeholder _resolved_src[{score:{name:"@s"}}] run data modify storage macroengine:placeholder _resolved_src[{score:{name:"@s"}}].score.name set value "@e[tag=macroengine.ph_caller,distance=..2,limit=1]"

# the whole text as one resolved component (a bare root makes it a single compound)
data modify storage macroengine:placeholder _src set from storage macroengine:placeholder _resolved_src
data modify storage macroengine:placeholder _src prepend value {text:""}
item modify entity @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1] container.0 macroengine:placeholder/name
data modify storage macroengine:placeholder resolved set from entity @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1] Items[{Slot:0b}].components."minecraft:custom_name"
data modify storage macroengine:placeholder custom_name set from storage macroengine:placeholder resolved
execute unless data storage macroengine:placeholder custom_name.italic run data modify storage macroengine:placeholder custom_name.italic set value false

# lore: cut `out` into lines (using the @s-rebound copy), then let the server
# resolve them one at a time
data modify storage macroengine:placeholder _line set value []
data modify storage macroengine:placeholder _rest set from storage macroengine:placeholder _resolved_src
function macroengine:core/internal/api/placeholder/_lore_loop
item modify entity @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1] container.0 macroengine:lore_clear
data modify storage macroengine:placeholder _rest set from storage macroengine:placeholder lore_live
function macroengine:core/internal/api/placeholder/_lore_apply
execute if data entity @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1] Items[{Slot:0b}].components."minecraft:lore" run data modify storage macroengine:placeholder lore set from entity @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1] Items[{Slot:0b}].components."minecraft:lore"

# plain string
function macroengine:core/internal/api/placeholder/_plain

# empty the scratch item before killing the minecart: a chest minecart drops
# its container contents on death, which otherwise hands the player a stray
# minecraft:stone standing next to it
item replace entity @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1] container.0 with minecraft:air
kill @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1]
tag @s remove macroengine.ph_caller
data remove storage macroengine:placeholder _src
data remove storage macroengine:placeholder _resolved_src
data remove storage macroengine:placeholder _cur
data remove storage macroengine:placeholder _rest
data remove storage macroengine:placeholder _line
data remove storage macroengine:placeholder lore_live
