# Archive gate: the original load hooks only run after an operator approved them.
scoreboard objectives add vcm_archive dummy
execute unless score #guikit_datapack vcm_archive matches 1 run scoreboard players set #guikit_datapack vcm_archive 0
execute if score #guikit_datapack vcm_archive matches 1 run function #vcm_archive_guikit_datapack:orig_load
