scoreboard objectives add vcm_archive dummy
scoreboard players set #interactionclickdetection vcm_archive 1
tag @a remove vcm_archive_interactionclickdetection_seen
tellraw @s [{"text":"[ARCHIVED] ","color":"red","bold":true},{"text":"InteractionClickDetection approved. Running its load hooks now. Revoke with ","color":"gray"},{"text":"/function vcm_archive_interactionclickdetection:revoke","color":"yellow"}]
function #vcm_archive_interactionclickdetection:orig_load
