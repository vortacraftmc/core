# macroengine:systems/nbt/internal/swap_exec [MACRO]
# INPUT: $(storage), $(path_a), $(path_b)

$data modify storage macroengine:engine _nbt_swap set from storage $(storage) $(path_a)
$data modify storage $(storage) $(path_a) set from storage $(storage) $(path_b)
$data modify storage $(storage) $(path_b) set from storage macroengine:engine _nbt_swap
data remove storage macroengine:engine _nbt_swap

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.nbt_swap","color":"aqua"},{"text":"$(path_a)","color":"white"},{"text":" ↔ ","color":"#555555"},{"text":"$(path_b)","color":"aqua"}]
