scoreboard objectives add vcm_archive dummy
scoreboard players set #tunnelscript vcm_archive 1
tag @a remove vcm_archive_tunnelscript_seen
tellraw @s [{"text":"[ARCHIVED] ","color":"red","bold":true},{"text":"TunnelScript approved. Running its load hooks now. Revoke with ","color":"gray"},{"text":"/function vcm_archive_tunnelscript:revoke","color":"yellow"}]
function #vcm_archive_tunnelscript:orig_load
