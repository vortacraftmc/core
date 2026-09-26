
$execute as @a[name=$(player),limit=1] at @s run playsound $(sound) master @s ~ ~ ~ $(volume) $(pitch)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cmd_sound","color":"aqua"},{"text":"$(player)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(sound)","color":"aqua"}]
