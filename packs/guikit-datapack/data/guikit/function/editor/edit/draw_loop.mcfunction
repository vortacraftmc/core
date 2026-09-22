execute unless data storage guikit:work src[0] run return 0
data modify storage guikit:work w set from storage guikit:work src[0]
function guikit:editor/edit/draw_one
data remove storage guikit:work src[0]
function guikit:editor/edit/draw_loop
