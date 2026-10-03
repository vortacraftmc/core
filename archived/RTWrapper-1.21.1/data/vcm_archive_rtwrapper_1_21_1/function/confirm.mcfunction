scoreboard objectives add vcm_archive dummy
scoreboard players set #rtwrapper_1_21_1 vcm_archive 1
tag @a remove vcm_archive_rtwrapper_1_21_1_seen
tellraw @s [{"text":"[ARCHIVED] ","color":"red","bold":true},{"text":"RTWrapper 1.21.1 approved. Running its load hooks now. Revoke with ","color":"gray"},{"text":"/function vcm_archive_rtwrapper_1_21_1:revoke","color":"yellow"}]
function #vcm_archive_rtwrapper_1_21_1:orig_load
