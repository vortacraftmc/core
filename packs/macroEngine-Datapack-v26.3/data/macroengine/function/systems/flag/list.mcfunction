tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.header.global_flags","color":"aqua"},{"translate":"macroengine.ui.sep11","color":"#555555"}]
execute if data storage macroengine:engine flags run tellraw @a[tag=macroengine.debug] ["",{"text":" ","color":"#555555"},{"plain":true ,"storage":"macroengine:engine","nbt":"flags","interpret":false,"color":"white"}]
execute unless data storage macroengine:engine flags run tellraw @a[tag=macroengine.debug] ["",{"text":" ","color":"#555555"},{"translate":"macroengine.debug.no_flags","color":"gray","italic":true}]
tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"text":"━━━━━━━━━━━━━━━━━━━","color":"#555555"}]
