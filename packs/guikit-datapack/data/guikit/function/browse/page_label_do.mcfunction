# macro: $(page) $(count)
function guikit:internal/clear/w
data modify storage guikit:w slot set value 19
data modify storage guikit:w item set value "minecraft:paper"
data modify storage guikit:w id set value "bpage"
data modify storage guikit:w type set value "decor"
$data modify storage guikit:w name set value {text:"Page $(page)",italic:false}
data modify storage guikit:w lore set value [{text:"18 per page",color:"dark_gray",italic:false}]
$function guikit:browse/count_lore {count:"$(count)"}
function guikit:browse/status_lore
function guikit:widget/draw
