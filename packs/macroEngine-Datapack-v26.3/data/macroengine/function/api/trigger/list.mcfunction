tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.header.trigger_binds","color":"aqua"},{"text":"━━━━━━━━━━━━━","color":"#555555"}]
execute unless data storage macroengine:engine trigger_binds[0] run tellraw @s ["",{"text":" ","color":"#555555"},{"translate":"macroengine.trigger.no_binds","color":"gray","italic":true}]
execute if data storage macroengine:engine trigger_binds[0] run tellraw @s ["",{"text":" ","color":"#555555"},{"nbt":"trigger_binds","plain":true ,"storage":"macroengine:engine","interpret":false,"color":"yellow"}]
tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.ui.sep30","color":"#555555"}]
