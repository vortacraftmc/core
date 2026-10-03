scoreboard objectives add vcm_archive dummy
scoreboard players set #macroengine_datapack_v26_4 vcm_archive 1
tag @a remove vcm_archive_macroengine_datapack_v26_4_seen
tellraw @s [{"text":"[ARCHIVED] ","color":"red","bold":true},{"text":"macroEngine v26.4 approved. Running its load hooks now. Revoke with ","color":"gray"},{"text":"/function vcm_archive_macroengine_datapack_v26_4:revoke","color":"yellow"}]
function #vcm_archive_macroengine_datapack_v26_4:orig_load
