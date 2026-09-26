data remove storage macroengine:output result
$execute if data storage macroengine:engine states.$(player) run data modify storage macroengine:output result set from storage macroengine:engine states.$(player)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.state_get","color":"aqua"},{"text":"$(player)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"plain":true ,"storage":"macroengine:output","nbt":"result","color":"green"}]
