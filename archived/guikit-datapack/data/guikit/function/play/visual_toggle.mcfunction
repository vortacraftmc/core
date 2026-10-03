execute store result storage guikit:work pid int 1 run scoreboard players get @s guikit.pid
data modify storage guikit:work key set from storage guikit:work w.key
function guikit:play/visual_toggle_do with storage guikit:work
