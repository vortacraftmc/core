
$execute as @a[name=$(player),limit=1] at @s run effect give @s minecraft:instant_health 1 $(amount) true
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cmd_heal","color":"aqua"},{"text":"$(player)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(amount)","color":"aqua"}]
