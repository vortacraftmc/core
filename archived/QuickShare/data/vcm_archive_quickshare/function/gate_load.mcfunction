# Archive gate: the original load hooks only run after an operator approved them.
scoreboard objectives add vcm_archive dummy
execute unless score #quickshare vcm_archive matches 1 run scoreboard players set #quickshare vcm_archive 0
execute if score #quickshare vcm_archive matches 1 run function #vcm_archive_quickshare:orig_load
