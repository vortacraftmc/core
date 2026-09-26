tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.header.events","color":"aqua"},{"text":"━━━━━━","color":"#555555"}]
execute if data storage macroengine:engine events run tellraw @a[tag=macroengine.debug] ["",{"text":" ","color":"#555555"},{"plain":true ,"storage":"macroengine:engine","nbt":"events","interpret":false,"color":"yellow"}]
execute unless data storage macroengine:engine events run tellraw @a[tag=macroengine.debug] ["",{"text":" ","color":"#555555"},{"translate":"macroengine.debug.no_events","color":"gray","italic":true}]
tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.ui.sep22","color":"#555555"}]
