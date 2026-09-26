$execute store result score $cv macroengine.tmp run data get storage macroengine:engine players.$(player).$(key)
$scoreboard players set $cv_mn macroengine.tmp $(min)
$scoreboard players set $cv_mx macroengine.tmp $(max)
execute if score $cv macroengine.tmp < $cv_mn macroengine.tmp run scoreboard players operation $cv macroengine.tmp = $cv_mn macroengine.tmp
execute if score $cv macroengine.tmp > $cv_mx macroengine.tmp run scoreboard players operation $cv macroengine.tmp = $cv_mx macroengine.tmp
$execute store result storage macroengine:engine players.$(player).$(key) int 1 run scoreboard players get $cv macroengine.tmp
execute store result storage macroengine:output result int 1 run scoreboard players get $cv macroengine.tmp
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.player_clamp_var","color":"aqua"},{"text":"$(player)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(key)","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"plain":true ,"storage":"macroengine:output","nbt":"result","color":"green"}]
