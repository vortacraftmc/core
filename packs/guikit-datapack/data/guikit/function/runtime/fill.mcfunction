# guikit :: runtime/fill     #guikit:fill — no-op unless this open was bound by the editor/player
execute unless score @s guikit.uid matches 1.. run return 0
execute store result storage guikit:ctx uid int 1 run scoreboard players get @s guikit.uid
function guikit:runtime/fill_load with storage guikit:ctx
