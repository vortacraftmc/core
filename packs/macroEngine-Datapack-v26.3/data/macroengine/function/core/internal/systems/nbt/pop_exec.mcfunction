# macroengine:systems/nbt/internal/pop_exec [MACRO]
# INPUT: $(storage), $(path)

$execute if data storage $(storage) $(path)[0] run data modify storage macroengine:output result set from storage $(storage) $(path)[0]
$execute if data storage $(storage) $(path)[0] run data remove storage $(storage) $(path)[0]
$execute unless data storage $(storage) $(path)[0] run data modify storage macroengine:output result set value 0b

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.nbt_pop","color":"aqua"},{"text":"$(storage):$(path)","color":"white"}]
