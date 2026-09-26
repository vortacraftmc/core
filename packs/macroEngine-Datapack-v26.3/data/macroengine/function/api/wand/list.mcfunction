# macroengine:api/wand/list — Shows registered wand binds.
tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.header.wand_binds","color":"aqua"},{"translate":"macroengine.ui.sep15","color":"#555555"}]
execute unless data storage macroengine:engine wand_binds[0] run tellraw @s ["",{"text":" ","color":"#555555"},{"translate":"macroengine.wand.no_binds","color":"gray","italic":true}]
execute if data storage macroengine:engine wand_binds[0] run tellraw @s ["",{"text":" ","color":"#555555"},{"plain":true ,"storage":"macroengine:engine","nbt":"wand_binds","interpret":false,"color":"yellow"}]
tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.ui.sep32","color":"#555555"}]
