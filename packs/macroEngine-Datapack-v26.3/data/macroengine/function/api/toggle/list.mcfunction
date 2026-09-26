# macroengine:api/toggle/list
# Prints the enabled/disabled state of all DL modules.
#
# Usage:  function macroengine:api/toggle/list
# Caller: macroengine.admin tag required

execute unless entity @s[tag=macroengine.admin] run return 0

tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.header.module_states","color":"#555555"}]
tellraw @s ["",{"text":" ","color":"#555555"},{"plain":true ,"storage":"macroengine:engine","nbt":"modules","interpret":false,"color":"yellow"}]
tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.ui.sep33","color":"#555555"}]
