# macro: $(i)
function guikit:internal/clear/w
$data modify storage guikit:w slot set value $(i)
data modify storage guikit:w item set value "minecraft:light_gray_stained_glass_pane"
data modify storage guikit:w type set value "edit"
$data modify storage guikit:w id set value "eds$(i)"
$data modify storage guikit:w name set value {text:"Slot $(i)",color:"dark_gray",italic:false}
data modify storage guikit:w lore set value [{text:"Hold an item, then click",color:"gray",italic:false}]
function guikit:widget/draw
