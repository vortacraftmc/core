# macroengine:api/toggle/perm/false — Disable the perm trigger module

execute unless entity @s[tag=macroengine.admin] run return 0

data modify storage macroengine:engine modules.perm set value 0b
tellraw @s {"text":"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"}

tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.mod.perm","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"translate":"macroengine.state.disabled","color":"red"}]
# # tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.toggle_perm","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"translate":"macroengine.ui.false","color":"red"}]
