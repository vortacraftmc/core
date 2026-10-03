# Archive gate: the original load hooks only run after an operator approved them.
scoreboard objectives add vcm_archive dummy
execute unless score #macroengine_datapack_v26_4 vcm_archive matches 1 run scoreboard players set #macroengine_datapack_v26_4 vcm_archive 0
execute if score #macroengine_datapack_v26_4 vcm_archive matches 1 run function #vcm_archive_macroengine_datapack_v26_4:orig_load
