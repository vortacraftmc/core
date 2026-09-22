function guikit:widget/pad
data modify storage guikit:work list set from storage guikit:lib order
scoreboard players set #slot guikit.tmp 0
scoreboard players set #drawn guikit.tmp 0
function guikit:browse/draw_loop
function guikit:internal/clear/w
data modify storage guikit:w slot set value 26
data modify storage guikit:w item set value "minecraft:barrier"
data modify storage guikit:w id set value "bclose"
data modify storage guikit:w type set value "tool"
data modify storage guikit:w name set value {text:"Close",color:"red",italic:false}
data modify storage guikit:w lore set value []
function guikit:widget/draw
execute if score #drawn guikit.tmp matches 0 run function guikit:browse/empty
