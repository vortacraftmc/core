# macroengine:systems/nbt/internal/move_exec [MACRO]
# INPUT: $(storage), $(from_path), $(to_path)

$data modify storage $(storage) $(to_path) set from storage $(storage) $(from_path)
$data remove storage $(storage) $(from_path)
