# macroengine:core/lib/batch/internal/begin_exec [MACRO]
# INPUT: $(id), $(spread_over)

$data modify storage macroengine:engine batches.$(id) set value {items:[],spread_over:$(spread_over),flushed:0b}

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_batch_begin","color":"aqua"},{"text":"$(id)","color":"white"},{"translate":"macroengine.fmt.spread","color":"#555555"}]
