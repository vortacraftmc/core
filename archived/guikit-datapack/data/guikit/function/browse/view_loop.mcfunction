execute unless data storage guikit:work src[0] run return 0
data modify storage guikit:work id set from storage guikit:work src[0]
function guikit:browse/view_one with storage guikit:work
data remove storage guikit:work src[0]
function guikit:browse/view_loop
