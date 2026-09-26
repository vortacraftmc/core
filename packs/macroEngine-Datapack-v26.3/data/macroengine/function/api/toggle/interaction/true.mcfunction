# macroengine:api/toggle/interaction/true — Enable the interaction (IE) module

execute unless entity @s[tag=macroengine.admin] run return 0

data modify storage macroengine:engine modules.interaction set value 1b
tellraw @s {"text":"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"}

tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.mod.interaction","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"translate":"macroengine.state.enabled","color":"green"}]
# # tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.toggle_interaction","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"translate":"macroengine.ui.true","color":"green"}]
