# macroengine:systems/nbt/internal/append_exec [MACRO]
# INPUT: $(dst_storage), $(dst_path), $(src_storage), $(src_path)

$data modify storage $(dst_storage) $(dst_path) append from storage $(src_storage) $(src_path)

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.nbt_append","color":"aqua"},{"text":"$(src_storage):$(src_path)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(dst_storage):$(dst_path)","color":"aqua"}]
