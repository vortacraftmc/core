# macroengine:api/color/palette_list
# Prints all registered palette entries to the calling player.
# Requires macroengine.admin tag.
#
# Usage:
#   function macroengine:api/color/palette_list

execute unless entity @s[tag=macroengine.admin] run return 0

tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.header.color_palette","color":"aqua"},{"translate":"macroengine.ui.sep11","color":"#555555"}]
execute if data storage macroengine:engine color.palette run tellraw @s ["",{"text":" ","color":"#555555"},{"plain":true ,"storage":"macroengine:engine","nbt":"color.palette","interpret":false,"color":"green"}]
execute unless data storage macroengine:engine color.palette run tellraw @s ["",{"text":" ","color":"#555555"},{"translate":"macroengine.color.palette_empty","color":"gray","italic":true}]
tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.ui.sep29","color":"#555555"}]
