scoreboard objectives add vcm_archive dummy
scoreboard players set #cmdtunnel_datapack vcm_archive 1
tag @a remove vcm_archive_cmdtunnel_datapack_seen
tellraw @s [{"text":"[ARCHIVED] ","color":"red","bold":true},{"text":"cmdTunnel approved. Running its load hooks now. Revoke with ","color":"gray"},{"text":"/function vcm_archive_cmdtunnel_datapack:revoke","color":"yellow"}]
function #vcm_archive_cmdtunnel_datapack:orig_load
