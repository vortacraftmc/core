
$execute as @a[name=$(player),limit=1] run xp add @s $(amount) $(type)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cmd_xp_add","color":"aqua"},{"text":"$(player)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(type)","color":"aqua"}]
