# macroengine:systems/nbt/internal/copy_exec [MACRO]
# INPUT: $(src_storage), $(src_path), $(dst_storage), $(dst_path)

$data modify storage $(dst_storage) $(dst_path) set from storage $(src_storage) $(src_path)

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.nbt_copy","color":"aqua"},{"text":"$(src_storage):$(src_path)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(dst_storage):$(dst_path)","color":"aqua"}]
