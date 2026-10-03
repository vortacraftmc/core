scoreboard objectives add vcm_archive dummy
scoreboard players set #guikit_demo vcm_archive 1
tag @a remove vcm_archive_guikit_demo_seen
tellraw @s [{"text":"[ARCHIVED] ","color":"red","bold":true},{"text":"guikit-demo approved. Running its load hooks now. Revoke with ","color":"gray"},{"text":"/function vcm_archive_guikit_demo:revoke","color":"yellow"}]
function #vcm_archive_guikit_demo:orig_load
