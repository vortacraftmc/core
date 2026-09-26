$execute as @a[name=$(player),limit=1] at @s unless items entity @s contents $(item)[minecraft:custom_data=$(customData)] run $(invoke)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.inv_player_unless_item","color":"aqua"},{"text":"$(player)","color":"white"}]
