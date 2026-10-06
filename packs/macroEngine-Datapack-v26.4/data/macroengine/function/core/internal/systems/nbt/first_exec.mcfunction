# macroengine:systems/nbt/internal/first_exec [MACRO]
# INPUT: $(src_storage), $(src_path), $(dst_storage), $(dst_path)

$data modify storage $(dst_storage) $(dst_path) set from storage $(src_storage) $(src_path)[0]
