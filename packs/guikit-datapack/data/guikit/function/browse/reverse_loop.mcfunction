execute unless data storage guikit:work src[0] run return 0
data modify storage guikit:work rev prepend from storage guikit:work src[0]
data remove storage guikit:work src[0]
function guikit:browse/reverse_loop
