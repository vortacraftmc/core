# Archive gate: original tick hooks only run once approved; until then each player gets the notice once.
execute if score #guikit_datapack vcm_archive matches 1 run function #vcm_archive_guikit_datapack:orig_tick
execute unless score #guikit_datapack vcm_archive matches 1 as @a unless entity @s[tag=vcm_archive_guikit_datapack_seen] run function vcm_archive_guikit_datapack:warn_player
