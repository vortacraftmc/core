execute unless data storage guikit:work list[0] run return 0
data modify storage guikit:work cmp set from storage guikit:work drop
execute store success score #diff guikit.tmp run data modify storage guikit:work cmp set from storage guikit:work list[0]
execute if score #diff guikit.tmp matches 1.. run data modify storage guikit:work out append from storage guikit:work list[0]
data remove storage guikit:work list[0]
function guikit:editor/ui/delete_order
