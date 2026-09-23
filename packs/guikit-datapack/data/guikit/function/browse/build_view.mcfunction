# published menus only, then this player's sort and container filter
data modify storage guikit:work src set from storage guikit:lib order
data modify storage guikit:work view set value []
execute if score @s guikit.bsort matches 1 run function guikit:browse/reverse_src
function guikit:browse/view_loop
