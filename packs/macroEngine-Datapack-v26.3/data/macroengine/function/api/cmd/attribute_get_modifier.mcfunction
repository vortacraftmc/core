
$execute store result storage macroengine:output result double 1 run attribute @a[name=$(player),limit=1] $(attribute) modifier value get $(id)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cmd_attribute_get_modifier","color":"aqua"},{"text":"$(player)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(id)","color":"aqua"}]
