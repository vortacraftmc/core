# macroengine:systems/nbt/internal/swap_exec [MACRO]
# INPUT: $(storage), $(path_a), $(path_b)

$data modify storage macroengine:engine _nbt_swap set from storage $(storage) $(path_a)
$data modify storage $(storage) $(path_a) set from storage $(storage) $(path_b)
$data modify storage $(storage) $(path_b) set from storage macroengine:engine _nbt_swap
data remove storage macroengine:engine _nbt_swap
