
$execute store result storage macroengine:output result int 1 run scoreboard players get @a[name=$(player),limit=1] $(objective)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cmd_scoreboard_get","color":"aqua"},{"text":"$(player)","color":"white"}]
