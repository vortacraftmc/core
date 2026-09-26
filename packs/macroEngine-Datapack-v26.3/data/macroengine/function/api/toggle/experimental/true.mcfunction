# macroengine:api/toggle/experimental/true [MACRO] — Enable one experimental flag
# Called by the experimental flags menu, or directly:
#   function macroengine:api/toggle/experimental/true {flag:"hologram"}
# Caller: macroengine.admin tag required

execute unless entity @s[tag=macroengine.admin] run return 0

$function macroengine:systems/flag/experimental/set {flag:"$(flag)",value:"1b"}

$tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.mod.experimental_pre","color":"gray"},{"text":"$(flag)","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"translate":"macroengine.state.enabled","color":"green"}]
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.toggle_experimental","color":"aqua"},{"text":"$(flag)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"translate":"macroengine.ui.true","color":"green"}]
