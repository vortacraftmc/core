scoreboard objectives add vcm_archive dummy
scoreboard players set #quickshare vcm_archive 1
tag @a remove vcm_archive_quickshare_seen
tellraw @s [{"text":"[ARCHIVED] ","color":"red","bold":true},{"text":"QuickShare approved. Running its load hooks now. Revoke with ","color":"gray"},{"text":"/function vcm_archive_quickshare:revoke","color":"yellow"}]
function #vcm_archive_quickshare:orig_load
