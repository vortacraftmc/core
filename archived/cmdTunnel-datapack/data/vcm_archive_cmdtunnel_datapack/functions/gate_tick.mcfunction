# Archive gate: original tick hooks only run once approved; until then each player gets the notice once.
execute if score #cmdtunnel_datapack vcm_archive matches 1 run function #vcm_archive_cmdtunnel_datapack:orig_tick
execute unless score #cmdtunnel_datapack vcm_archive matches 1 as @a unless entity @s[tag=vcm_archive_cmdtunnel_datapack_seen] run function vcm_archive_cmdtunnel_datapack:warn_player
