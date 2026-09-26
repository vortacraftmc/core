$execute as @a[name=$(player),limit=1] at @s if items entity @s contents $(item)[minecraft:custom_data=$(customData)] run $(invoke)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.inv_player_if_item","color":"aqua"},{"text":"$(player)","color":"white"}]
