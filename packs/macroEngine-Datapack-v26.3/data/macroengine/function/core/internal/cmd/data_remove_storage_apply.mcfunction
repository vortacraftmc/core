# macroengine:core/internal/cmd/data_remove_storage_apply
# The actual storage-removal logic.
$data remove storage $(storage) $(path)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cmd_data_remove_storage","color":"aqua"},{"text":"$(storage) → $(path)","color":"#555555"}]
