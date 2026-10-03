scoreboard objectives add vcm_archive dummy
scoreboard players set #leftclickdetection vcm_archive 1
tag @a remove vcm_archive_leftclickdetection_seen
tellraw @s [{"text":"[ARCHIVED] ","color":"red","bold":true},{"text":"LeftClickDetection approved. Running its load hooks now. Revoke with ","color":"gray"},{"text":"/function vcm_archive_leftclickdetection:revoke","color":"yellow"}]
function #vcm_archive_leftclickdetection:orig_load
