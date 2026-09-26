
$execute as @a[name=$(player),limit=1] run attribute @s $(attribute) base set $(value)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cmd_attribute_set","color":"aqua"},{"text":"$(player)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(value)","color":"aqua"}]
