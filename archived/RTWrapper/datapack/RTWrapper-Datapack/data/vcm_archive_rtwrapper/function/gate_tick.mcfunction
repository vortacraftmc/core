# Archive gate: original tick hooks only run once approved; until then each player gets the notice once.
execute if score #rtwrapper vcm_archive matches 1 run function #vcm_archive_rtwrapper:orig_tick
execute unless score #rtwrapper vcm_archive matches 1 as @a unless entity @s[tag=vcm_archive_rtwrapper_seen] run function vcm_archive_rtwrapper:warn_player
