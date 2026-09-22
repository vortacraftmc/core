function guikit:internal/clear/w
data modify storage guikit:w slot set value 22
data modify storage guikit:w item set value "minecraft:arrow"
data modify storage guikit:w id set value "pcancel"
data modify storage guikit:w type set value "tool"
data modify storage guikit:w name set value {text:"Back to editor",italic:false}
data modify storage guikit:w lore set value []
function guikit:widget/draw
