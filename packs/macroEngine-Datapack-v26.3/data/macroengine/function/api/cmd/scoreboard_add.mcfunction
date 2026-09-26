
$execute as @a[name=$(player),limit=1] at @s run scoreboard players add @s $(objective) $(amount)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cmd_scoreboard_add","color":"aqua"},{"text":"$(player)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(amount)","color":"aqua"}]
