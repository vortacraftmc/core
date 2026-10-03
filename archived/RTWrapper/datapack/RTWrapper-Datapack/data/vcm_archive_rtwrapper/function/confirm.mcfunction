scoreboard objectives add vcm_archive dummy
scoreboard players set #rtwrapper vcm_archive 1
tag @a remove vcm_archive_rtwrapper_seen
tellraw @s [{"text":"[ARCHIVED] ","color":"red","bold":true},{"text":"RTWrapper (original) approved. Running its load hooks now. Revoke with ","color":"gray"},{"text":"/function vcm_archive_rtwrapper:revoke","color":"yellow"}]
function #vcm_archive_rtwrapper:orig_load
