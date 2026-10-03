# Archive gate: original tick hooks only run once approved; until then each player gets the notice once.
execute if score #guikit_demo vcm_archive matches 1 run function #vcm_archive_guikit_demo:orig_tick
execute unless score #guikit_demo vcm_archive matches 1 as @a unless entity @s[tag=vcm_archive_guikit_demo_seen] run function vcm_archive_guikit_demo:warn_player
