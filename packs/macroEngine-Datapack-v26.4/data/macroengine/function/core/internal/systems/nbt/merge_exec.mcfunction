# macroengine:systems/nbt/internal/merge_exec [MACRO]
# INPUT: $(src_storage), $(src_path), $(dst_storage), $(dst_path)

$data modify storage $(dst_storage) $(dst_path) merge from storage $(src_storage) $(src_path)
