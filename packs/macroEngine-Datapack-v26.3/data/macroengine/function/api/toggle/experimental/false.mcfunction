# macroengine:api/toggle/experimental/false [MACRO] — Disable one experimental flag
# Called by the experimental flags menu, or directly:
#   function macroengine:api/toggle/experimental/false {flag:"hologram"}
# Caller: macroengine.admin tag required

execute unless entity @s[tag=macroengine.admin] run return 0

$function macroengine:systems/flag/experimental/set {flag:"$(flag)",value:"0b"}

$tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.mod.experimental_pre","color":"gray"},{"text":"$(flag)","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"translate":"macroengine.state.disabled","color":"red"}]
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.toggle_experimental","color":"aqua"},{"text":"$(flag)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"translate":"macroengine.ui.false","color":"red"}]
