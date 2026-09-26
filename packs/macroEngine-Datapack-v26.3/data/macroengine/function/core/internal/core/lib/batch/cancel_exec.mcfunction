# macroengine:core/lib/batch/internal/cancel_exec [MACRO]
# INPUT: $(id)

$execute unless data storage macroengine:engine batches.$(id) run return 0
$data remove storage macroengine:engine batches.$(id)

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_batch_cancel","color":"aqua"},{"text":"$(id)","color":"white"},{"translate":"macroengine.debug.cancelled","color":"#FF5555"}]
