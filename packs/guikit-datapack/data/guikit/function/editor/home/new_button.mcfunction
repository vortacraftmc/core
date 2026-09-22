function guikit:internal/clear/w
data modify storage guikit:w slot set value 22
data modify storage guikit:w item set value "minecraft:emerald"
data modify storage guikit:w id set value "hnew"
data modify storage guikit:w type set value "tool"
data modify storage guikit:w name set value {text:"New menu",color:"green",italic:false}
data modify storage guikit:w lore set value [{text:"Creates an empty menu",color:"gray",italic:false}]
function guikit:widget/draw
function guikit:internal/clear/w
data modify storage guikit:w slot set value 23
data modify storage guikit:w item set value "minecraft:knowledge_book"
data modify storage guikit:w id set value "hhelp"
data modify storage guikit:w type set value "tool"
data modify storage guikit:w name set value {text:"Help",color:"aqua",italic:false}
data modify storage guikit:w lore set value []
function guikit:widget/draw
