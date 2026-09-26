# macroengine:experimental/crafting_ui/show
# Prints a clickable "custom crafting" shortcut menu.
#
# Usage:  function macroengine:experimental/crafting_ui/show
# Caller: any player

execute unless data storage macroengine:engine flags.experimental{crafting_ui:1b} run tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.exp.crafting_ui_disabled","color":"red"}]
execute unless data storage macroengine:engine flags.experimental{crafting_ui:1b} run return 0

tellraw @s ["",{"translate":"macroengine.ui.eq_pre","color":"dark_gray"},{"translate":"macroengine.exp.recipes_title","color":"aqua","bold":true},{"translate":"macroengine.ui.eq_post","color":"dark_gray"}]
tellraw @s ["",{"translate":"macroengine.exp.recipes_hint","color":"gray","italic":true}]
function #macroengine:cui/list_recipes
tellraw @s ["",{"translate":"macroengine.ui.eq37","color":"dark_gray"}]
