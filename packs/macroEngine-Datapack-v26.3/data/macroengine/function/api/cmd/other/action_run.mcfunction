$execute as @a[name=$(player),limit=1] at @s run function macroengine:api/cmd/$(type) $(arguments)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cmd_other_action_run","color":"aqua"},{"text":"$(player)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(type)","color":"aqua"}]
