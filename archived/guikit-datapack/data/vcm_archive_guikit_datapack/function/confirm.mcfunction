scoreboard objectives add vcm_archive dummy
scoreboard players set #guikit_datapack vcm_archive 1
tag @a remove vcm_archive_guikit_datapack_seen
tellraw @s [{"text":"[ARCHIVED] ","color":"red","bold":true},{"text":"guikit approved. Running its load hooks now. Revoke with ","color":"gray"},{"text":"/function vcm_archive_guikit_datapack:revoke","color":"yellow"}]
function #vcm_archive_guikit_datapack:orig_load
