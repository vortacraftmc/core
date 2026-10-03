# Archive gate: original tick hooks only run once approved; until then each player gets the notice once.
execute if score #dailybonus vcm_archive matches 1 run function #vcm_archive_dailybonus:orig_tick
execute unless score #dailybonus vcm_archive matches 1 as @a unless entity @s[tag=vcm_archive_dailybonus_seen] run function vcm_archive_dailybonus:warn_player
