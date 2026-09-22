execute unless data storage guikit:work w.cd run return 0
function guikit:runtime/ensure_pid
execute store result storage guikit:work pid int 1 run scoreboard players get @s guikit.pid
execute store result storage guikit:work slot int 1 run data get storage guikit:work w.slot
function guikit:play/act/cd_check with storage guikit:work
execute if score #left guikit.tmp matches 1.. run function guikit:play/act/cd_wait
