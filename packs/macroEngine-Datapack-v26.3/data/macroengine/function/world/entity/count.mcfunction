scoreboard players set $ent_count macroengine.tmp 0
$execute as @e[type=$(type),tag=$(tag)] run scoreboard players add $ent_count macroengine.tmp 1
execute store result storage macroengine:output count int 1 run scoreboard players get $ent_count macroengine.tmp
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.entity_count","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(type)","color":"aqua"}]
