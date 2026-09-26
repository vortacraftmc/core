# macroengine:systems/nbt/internal/exists_exec [MACRO]
# INPUT: $(storage), $(path)

data modify storage macroengine:output result set value 0b
$execute if data storage $(storage) $(path) run data modify storage macroengine:output result set value 1b

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.nbt_exists","color":"aqua"},{"text":"$(storage):$(path)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"plain":true ,"storage":"macroengine:output","nbt":"result","color":"green"}]
