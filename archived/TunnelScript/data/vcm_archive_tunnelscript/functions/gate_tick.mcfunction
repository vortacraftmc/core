# Archive gate: original tick hooks only run once approved; until then each player gets the notice once.
execute if score #tunnelscript vcm_archive matches 1 run function #vcm_archive_tunnelscript:orig_tick
execute unless score #tunnelscript vcm_archive matches 1 as @a unless entity @s[tag=vcm_archive_tunnelscript_seen] run function vcm_archive_tunnelscript:warn_player
