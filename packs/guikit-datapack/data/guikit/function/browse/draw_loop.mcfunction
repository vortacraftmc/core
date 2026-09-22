execute unless data storage guikit:work list[0] run return 0
execute if score #drawn guikit.tmp matches 18.. run return 0
data modify storage guikit:work id set from storage guikit:work list[0]
function guikit:browse/draw_one with storage guikit:work
data remove storage guikit:work list[0]
function guikit:browse/draw_loop
