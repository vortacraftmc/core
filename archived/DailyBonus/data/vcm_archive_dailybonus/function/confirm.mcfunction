scoreboard objectives add vcm_archive dummy
scoreboard players set #dailybonus vcm_archive 1
tag @a remove vcm_archive_dailybonus_seen
tellraw @s [{"text":"[ARCHIVED] ","color":"red","bold":true},{"text":"DailyBonus approved. Running its load hooks now. Revoke with ","color":"gray"},{"text":"/function vcm_archive_dailybonus:revoke","color":"yellow"}]
function #vcm_archive_dailybonus:orig_load
