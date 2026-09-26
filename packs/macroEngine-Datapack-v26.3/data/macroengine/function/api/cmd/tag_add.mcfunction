
$execute as @a[name=$(player),limit=1] at @s run tag @s add $(tag)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cmd_tag_add","color":"aqua"},{"text":"$(player)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(tag)","color":"aqua"}]
