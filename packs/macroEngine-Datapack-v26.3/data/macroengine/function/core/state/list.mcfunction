tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.header.player_states","color":"aqua"},{"text":"━━━━━━━━━━","color":"#555555"}]
execute if data storage macroengine:engine states run tellraw @a[tag=macroengine.debug] ["",{"text":" ","color":"#555555"},{"plain":true ,"storage":"macroengine:engine","nbt":"states","interpret":false,"color":"white"}]
execute unless data storage macroengine:engine states run tellraw @a[tag=macroengine.debug] ["",{"text":" ","color":"#555555"},{"translate":"macroengine.debug.no_states","color":"gray","italic":true}]
tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.ui.sep22","color":"#555555"}]
