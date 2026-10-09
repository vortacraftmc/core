# macroengine:api/placeholder/list
# Prints every registered placeholder (name and component) to the executor.
tellraw @s [{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"placeholders: ","color":"gray"},{"storage":"macroengine:placeholder","nbt":"reg","plain":true,"interpret":false,"color":"white"}]
