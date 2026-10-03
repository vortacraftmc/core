# Archive gate: original tick hooks only run once approved; until then each player gets the notice once.
execute if score #leftclickdetection vcm_archive matches 1 run function #vcm_archive_leftclickdetection:orig_tick
execute unless score #leftclickdetection vcm_archive matches 1 as @a unless entity @s[tag=vcm_archive_leftclickdetection_seen] run function vcm_archive_leftclickdetection:warn_player
