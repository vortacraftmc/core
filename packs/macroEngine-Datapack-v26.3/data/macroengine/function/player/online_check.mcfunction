data modify storage macroengine:output result set value 0b
$execute if entity @a[name=$(player),limit=1] run data modify storage macroengine:output result set value 1b
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.player_online_check","color":"aqua"},{"text":"$(player)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"plain":true ,"storage":"macroengine:output","nbt":"result","color":"green"}]
