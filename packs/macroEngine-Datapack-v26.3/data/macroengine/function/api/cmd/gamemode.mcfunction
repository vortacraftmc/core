


$execute as @a[name=$(player),limit=1] at @s run gamemode $(mode) @s
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cmd_gamemode","color":"aqua"},{"text":"$(player)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(mode)","color":"aqua"}]
