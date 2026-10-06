# macroengine:systems/nbt/internal/append_exec [MACRO]
# INPUT: $(dst_storage), $(dst_path), $(src_storage), $(src_path)

$data modify storage $(dst_storage) $(dst_path) append from storage $(src_storage) $(src_path)