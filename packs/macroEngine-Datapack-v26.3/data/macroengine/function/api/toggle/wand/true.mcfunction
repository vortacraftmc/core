# macroengine:api/toggle/wand/true — Enable the wand module

execute unless entity @s[tag=macroengine.admin] run return 0

data modify storage macroengine:engine modules.wand set value 1b
tellraw @s {"text":"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"}

tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.mod.wand","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"translate":"macroengine.state.enabled","color":"green"}]
# # tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.toggle_wand","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"translate":"macroengine.ui.true","color":"green"}]
