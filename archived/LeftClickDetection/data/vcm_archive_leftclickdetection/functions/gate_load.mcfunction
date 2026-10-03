# Archive gate: the original load hooks only run after an operator approved them.
scoreboard objectives add vcm_archive dummy
execute unless score #leftclickdetection vcm_archive matches 1 run scoreboard players set #leftclickdetection vcm_archive 0
execute if score #leftclickdetection vcm_archive matches 1 run function #vcm_archive_leftclickdetection:orig_load
