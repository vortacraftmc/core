# Archive gate: original tick hooks only run once approved; until then each player gets the notice once.
execute if score #quickshare vcm_archive matches 1 run function #vcm_archive_quickshare:orig_tick
execute unless score #quickshare vcm_archive matches 1 as @a unless entity @s[tag=vcm_archive_quickshare_seen] run function vcm_archive_quickshare:warn_player
