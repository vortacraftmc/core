# macroengine:experimental/scoreboard_hud/hide [INTERNAL]
scoreboard objectives setdisplay sidebar
scoreboard players set #exp_hud_on macroengine.tmp 0
tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.exp.scoreboard_hud","color":"gray"},{"translate":"macroengine.state.off","color":"red"}]
