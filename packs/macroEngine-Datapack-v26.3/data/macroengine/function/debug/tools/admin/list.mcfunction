
tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.header.admin_list","color":"aqua"},{"text":"━━━━━━━━━━━━━━","color":"#555555"}]
execute if entity @a[tag=macroengine.admin] run tellraw @s ["",{"text":" ◈ ","color":"#00AAAA"},{"selector":"@a[tag=macroengine.admin]","color":"white"}]
execute unless entity @a[tag=macroengine.admin] run tellraw @s ["",{"text":" ","color":"#555555"},{"translate":"macroengine.admin.none","color":"gray","italic":true}]
tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.ui.sep33","color":"#555555"}]
