# macroengine:api/toggle/hook/true — Enable the hook module
# Called by the module toggle dialog when State = true.
# Caller: macroengine.admin tag required (enforced by dialog show guard in show.mcfunction)

execute unless entity @s[tag=macroengine.admin] run return 0

data modify storage macroengine:engine modules.hook set value 1b
tellraw @s {"text":"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"}

tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.mod.hook","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"translate":"macroengine.state.enabled","color":"green"}]
# # tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.toggle_hook","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"translate":"macroengine.ui.true","color":"green"}]
