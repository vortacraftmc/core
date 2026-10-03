# Archive gate: the original load hooks only run after an operator approved them.
scoreboard objectives add vcm_archive dummy
execute unless score #rtwrapper_v1_0_1 vcm_archive matches 1 run scoreboard players set #rtwrapper_v1_0_1 vcm_archive 0
execute if score #rtwrapper_v1_0_1 vcm_archive matches 1 run function #vcm_archive_rtwrapper_v1_0_1:orig_load
