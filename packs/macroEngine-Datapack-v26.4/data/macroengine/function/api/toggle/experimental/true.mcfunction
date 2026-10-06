# macroengine:api/toggle/experimental/true [MACRO] — Enable one experimental flag
# Called by the experimental flags menu, or directly:
#   function macroengine:api/toggle/experimental/true {flag:"hologram"}
# Caller: macroengine.admin tag required

execute unless entity @s[tag=macroengine.admin] run return 0

$function macroengine:systems/flag/experimental/set {flag:"$(flag)",value:"1b"}

$tellraw @s ["",{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"experimental/","color":"gray"},{"text":"$(flag)","color":"aqua"},{"text":" → ","color":"#555555"},{"text":"enabled","color":"green"}]