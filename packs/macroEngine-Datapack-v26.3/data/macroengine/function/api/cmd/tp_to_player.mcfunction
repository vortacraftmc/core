

$execute as @a[name=$(player),limit=1] at @s run tp @s @a[name=$(target),limit=1]
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cmd_tp_to_player","color":"aqua"},{"text":"$(player)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(target)","color":"aqua"}]
