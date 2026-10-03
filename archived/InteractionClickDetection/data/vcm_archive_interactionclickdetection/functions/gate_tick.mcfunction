# Archive gate: original tick hooks only run once approved; until then each player gets the notice once.
execute if score #interactionclickdetection vcm_archive matches 1 run function #vcm_archive_interactionclickdetection:orig_tick
execute unless score #interactionclickdetection vcm_archive matches 1 as @a unless entity @s[tag=vcm_archive_interactionclickdetection_seen] run function vcm_archive_interactionclickdetection:warn_player
