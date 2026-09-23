function guikit:internal/clear/w
data modify storage guikit:w slot set value 21
data modify storage guikit:w item set value "minecraft:comparator"
data modify storage guikit:w id set value "bsort"
data modify storage guikit:w type set value "tool"
data modify storage guikit:w name set value {text:"Sort: oldest",italic:false}
execute if score @s guikit.bsort matches 1 run data modify storage guikit:w name set value {text:"Sort: newest",color:"aqua",italic:false}
data modify storage guikit:w lore set value [{text:"Click to cycle",color:"gray",italic:false},{text:"/trigger guikit.sort",color:"dark_gray",italic:false}]
function guikit:widget/draw
