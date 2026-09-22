execute unless data storage guikit:work w.cmd run scoreboard players set #acted guikit.tmp 0
execute unless data storage guikit:work w.cmd run return run tellraw @s {"text":"[GUI] This button has no command.","color":"red"}
function guikit:play/act/cmd_do with storage guikit:work w
