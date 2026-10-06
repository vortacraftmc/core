# macroengine:systems/nbt/internal/exists_exec [MACRO]
# INPUT: $(storage), $(path)

data modify storage macroengine:output result set value 0b
$execute if data storage $(storage) $(path) run data modify storage macroengine:output result set value 1b