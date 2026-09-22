execute if score #hit guikit.tmp matches 1.. run return 0
execute unless data storage guikit:work src[0] run return 0
data modify storage guikit:work w set from storage guikit:work src[0]
execute if data storage guikit:work w{kind:"decor"} run data remove storage guikit:work src[0]
execute if data storage guikit:work w{kind:"decor"} run return run function guikit:play/probe_loop
execute store result score #slot guikit.tmp run data get storage guikit:work w.slot
execute store result storage guikit:work slot int 1 run scoreboard players get #slot guikit.tmp
function guikit:play/probe_one with storage guikit:work
data remove storage guikit:work src[0]
function guikit:play/probe_loop
