$scoreboard players set $cd_dur macroengine.tmp $(duration)
execute store result score $cd_now macroengine.tmp run scoreboard players get $epoch macroengine.time
scoreboard players operation $cd_now macroengine.tmp += $cd_dur macroengine.tmp
$execute store result storage macroengine:engine cooldowns.$(player).$(key) int 1 run scoreboard players get $cd_now macroengine.tmp
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cooldown_set","color":"aqua"},{"translate":"macroengine.ui.arrow_sp","color":"#555555"},{"text":"$(player)","color":"white"},{"text":":","color":"#555555"},{"text":"$(key)","color":"aqua"},{"translate":"macroengine.fmt.for","color":"#555555"},{"text":"$(duration)","color":"green"},{"text":"t","color":"#555555"}]
