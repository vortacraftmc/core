execute if score #i guikit.tmp matches 26.. run return 0
execute store result storage guikit:work i int 1 run scoreboard players get #i guikit.tmp
function guikit:editor/edit/placeholder with storage guikit:work
scoreboard players add #i guikit.tmp 1
function guikit:editor/edit/placeholders
