$data modify storage macroengine:engine _felist_state set value {func:"$(func)"}
scoreboard players set $felist_i macroengine.tmp 0
function macroengine:core/internal/core/lib/for_each_list_step

data remove storage macroengine:engine _felist_input
data remove storage macroengine:engine _felist_state
data remove storage macroengine:engine _felist_current
data remove storage macroengine:engine _felist_i
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_for_each_list","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(func)","color":"aqua"}]
