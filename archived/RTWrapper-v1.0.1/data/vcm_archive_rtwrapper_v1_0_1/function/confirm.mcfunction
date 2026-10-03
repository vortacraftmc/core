scoreboard objectives add vcm_archive dummy
scoreboard players set #rtwrapper_v1_0_1 vcm_archive 1
tag @a remove vcm_archive_rtwrapper_v1_0_1_seen
tellraw @s [{"text":"[ARCHIVED] ","color":"red","bold":true},{"text":"RTWrapper v1.0.1 approved. Running its load hooks now. Revoke with ","color":"gray"},{"text":"/function vcm_archive_rtwrapper_v1_0_1:revoke","color":"yellow"}]
function #vcm_archive_rtwrapper_v1_0_1:orig_load
