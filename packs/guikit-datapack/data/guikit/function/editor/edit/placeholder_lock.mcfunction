# macro: $(i)
function guikit:internal/clear/w
$data modify storage guikit:w slot set value $(i)
data modify storage guikit:w item set value "minecraft:red_stained_glass_pane"
data modify storage guikit:w type set value "edit"
data modify storage guikit:w id set value "edlock"
data modify storage guikit:w name set value {text:"Not in this container",color:"red",italic:false}
data modify storage guikit:w lore set value [{text:"Change container in Tools",color:"gray",italic:false}]
function guikit:widget/draw
