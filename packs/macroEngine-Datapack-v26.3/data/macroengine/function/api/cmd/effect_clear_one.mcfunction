
$execute as @a[name=$(player),limit=1] at @s run effect clear @s $(effect)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cmd_effect_clear_one","color":"aqua"},{"text":"$(player)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(effect)","color":"aqua"}]
