# macroengine:api/toggle/wand/true — Enable the wand module

execute unless entity @s[tag=macroengine.admin] run return 0

data modify storage macroengine:engine modules.wand set value 1b


tellraw @s ["",{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"wand","color":"aqua"},{"text":" → ","color":"#555555"},{"text":"enabled","color":"green"}]