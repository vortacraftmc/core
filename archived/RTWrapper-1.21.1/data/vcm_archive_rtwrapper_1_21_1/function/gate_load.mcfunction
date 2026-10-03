# Archive gate: the original load hooks only run after an operator approved them.
scoreboard objectives add vcm_archive dummy
execute unless score #rtwrapper_1_21_1 vcm_archive matches 1 run scoreboard players set #rtwrapper_1_21_1 vcm_archive 0
execute if score #rtwrapper_1_21_1 vcm_archive matches 1 run function #vcm_archive_rtwrapper_1_21_1:orig_load
