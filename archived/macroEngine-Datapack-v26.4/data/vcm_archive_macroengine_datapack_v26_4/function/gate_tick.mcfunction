# Archive gate: original tick hooks only run once approved; until then each player gets the notice once.
execute if score #macroengine_datapack_v26_4 vcm_archive matches 1 run function #vcm_archive_macroengine_datapack_v26_4:orig_tick
execute unless score #macroengine_datapack_v26_4 vcm_archive matches 1 as @a unless entity @s[tag=vcm_archive_macroengine_datapack_v26_4_seen] run function vcm_archive_macroengine_datapack_v26_4:warn_player
