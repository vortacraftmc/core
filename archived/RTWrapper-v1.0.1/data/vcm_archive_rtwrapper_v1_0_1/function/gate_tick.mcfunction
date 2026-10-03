# Archive gate: original tick hooks only run once approved; until then each player gets the notice once.
execute if score #rtwrapper_v1_0_1 vcm_archive matches 1 run function #vcm_archive_rtwrapper_v1_0_1:orig_tick
execute unless score #rtwrapper_v1_0_1 vcm_archive matches 1 as @a unless entity @s[tag=vcm_archive_rtwrapper_v1_0_1_seen] run function vcm_archive_rtwrapper_v1_0_1:warn_player
