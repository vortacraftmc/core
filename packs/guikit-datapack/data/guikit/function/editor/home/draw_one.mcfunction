# macro: $(id)
data remove storage guikit:work menu
$data modify storage guikit:work menu set from storage guikit:lib menus.$(id)
execute unless data storage guikit:work menu run return 0
execute store result storage guikit:w slot int 1 run scoreboard players get #slot guikit.tmp
data modify storage guikit:w item set value "minecraft:book"
data modify storage guikit:w type set value "menu"
$data modify storage guikit:w id set value "hm$(id)"
data modify storage guikit:w name set value {text:"Menu",italic:false,color:"white"}
data modify storage guikit:w name.text set from storage guikit:work menu.name
data modify storage guikit:w lore set value [{text:"Click to edit",color:"gray",italic:false}]
execute if data storage guikit:work menu{published:0b} run data modify storage guikit:w lore set value [{text:"Hidden from players",color:"red",italic:false}]
execute if data storage guikit:sess cur{mode:"pick"} run data modify storage guikit:w lore set value [{text:"Click to link",color:"aqua",italic:false}]
function guikit:widget/draw
scoreboard players add #slot guikit.tmp 1
scoreboard players add #drawn guikit.tmp 1
