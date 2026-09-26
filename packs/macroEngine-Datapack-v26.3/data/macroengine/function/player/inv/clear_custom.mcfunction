$execute as @a[name=$(player),limit=1] run clear @s $(item)[minecraft:custom_data=$(customData)] $(count)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.inv_clear_custom","color":"aqua"},{"text":"$(player)","color":"white"}]
