$data modify storage macroengine:engine _repeat.func set value "$(func)"
$scoreboard players set $rep_n macroengine.tmp $(count)
scoreboard players set $rep_i macroengine.tmp 0
execute store result storage macroengine:engine _repeat.i int 1 run scoreboard players get $rep_i macroengine.tmp
execute store result storage macroengine:engine _repeat.remaining int 1 run scoreboard players get $rep_n macroengine.tmp
function macroengine:core/internal/core/lib/repeat_run
data remove storage macroengine:engine _repeat
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_repeat","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(func)","color":"aqua"}]
