# macroengine:experimental/scoreboard_hud/show [INTERNAL]
scoreboard objectives setdisplay sidebar macroengine.exp_combat_timer
scoreboard players set #exp_hud_on macroengine.tmp 1
tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.exp.scoreboard_hud","color":"gray"},{"translate":"macroengine.state.on","color":"green"}]
