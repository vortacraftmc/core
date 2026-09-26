# macroengine:systems/nbt/internal/clear_exec [MACRO]
# INPUT: $(storage), $(path)

$data remove storage $(storage) $(path)

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.nbt_clear","color":"aqua"},{"text":"$(storage):$(path)","color":"white"}]
