
$execute as @a[name=$(player),limit=1] at @s run scoreboard players set @s $(objective) $(value)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cmd_scoreboard_set","color":"aqua"},{"text":"$(player)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(value)","color":"aqua"}]
