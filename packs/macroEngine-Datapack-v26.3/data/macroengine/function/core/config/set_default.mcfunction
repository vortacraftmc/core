data modify storage macroengine:output result set value 1b

$execute if data storage macroengine:engine config.$(key) run data modify storage macroengine:output result set value 0b
$execute if data storage macroengine:engine config.$(key) run return 0

$data modify storage macroengine:engine config.$(key) set value "$(value)"
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.config_set_default","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(key)","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"plain":true ,"storage":"macroengine:output","nbt":"result","color":"green"}]
