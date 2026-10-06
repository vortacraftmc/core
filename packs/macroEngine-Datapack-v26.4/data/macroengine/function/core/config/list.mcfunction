tellraw @s ["",{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"━━━ Config Values ","color":"aqua"},{"text":"━━━━━━━━━━━","color":"#555555"}]
execute if data storage macroengine:engine config run tellraw @s ["",{"text":" ","color":"#555555"},{"plain":true ,"storage":"macroengine:engine","nbt":"config","interpret":false,"color":"green"}]
execute unless data storage macroengine:engine config run tellraw @s ["",{"text":" ","color":"#555555"},{"text":"(no config values set)","color":"gray","italic":true}]
tellraw @s ["",{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━","color":"#555555"}]
