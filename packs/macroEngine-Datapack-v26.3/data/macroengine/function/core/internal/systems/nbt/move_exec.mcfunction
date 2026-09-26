# macroengine:systems/nbt/internal/move_exec [MACRO]
# INPUT: $(storage), $(from_path), $(to_path)

$data modify storage $(storage) $(to_path) set from storage $(storage) $(from_path)
$data remove storage $(storage) $(from_path)

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.nbt_move","color":"aqua"},{"text":"$(from_path)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(to_path)","color":"aqua"}]
