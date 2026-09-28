# macroengine:api/toggle/interaction/true — Enable the interaction (IE) module

execute unless entity @s[tag=macroengine.admin] run return 0

data modify storage macroengine:engine modules.interaction set value 1b


tellraw @s ["",{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"interaction","color":"aqua"},{"text":" → ","color":"#555555"},{"text":"enabled","color":"green"}]