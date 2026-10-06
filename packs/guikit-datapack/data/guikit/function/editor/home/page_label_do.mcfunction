# macro: $(page)
function guikit:internal/clear/w
data modify storage guikit:w slot set value 19
data modify storage guikit:w item set value "minecraft:paper"
data modify storage guikit:w id set value "hpage"
data modify storage guikit:w type set value "decor"
$data modify storage guikit:w name set value {text:"Page $(page)",italic:false}
data modify storage guikit:w lore set value [{text:"Refreshes every second",color:"gray",italic:false}]
function guikit:widget/draw
