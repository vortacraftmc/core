# Archive gate: the original load hooks only run after an operator approved them.
scoreboard objectives add vcm_archive dummy
execute unless score #tunnelscript vcm_archive matches 1 run scoreboard players set #tunnelscript vcm_archive 0
execute if score #tunnelscript vcm_archive matches 1 run function #vcm_archive_tunnelscript:orig_load
