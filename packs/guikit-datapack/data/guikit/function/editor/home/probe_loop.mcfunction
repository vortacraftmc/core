execute unless data storage guikit:work list[0] run return 0
execute if score #hit guikit.tmp matches 1.. run return 0
data modify storage guikit:work id set from storage guikit:work list[0]
function guikit:editor/home/probe_one with storage guikit:work
data remove storage guikit:work list[0]
function guikit:editor/home/probe_loop
