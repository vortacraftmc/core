# macroengine:experimental/waypoint/tp [MACRO]
# Teleports the caller to a stored waypoint (same-dimension only —
# does not cross-dimension teleport, kept out of scope for this
# first experimental pass).
#
# Usage:  function macroengine:experimental/waypoint/tp {name:"base"}
# Caller: any player

execute unless data storage macroengine:engine flags.experimental{waypoint:1b} run tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.exp.waypoint_disabled","color":"red"}]
execute unless data storage macroengine:engine flags.experimental{waypoint:1b} run return 0

$execute unless data storage macroengine:engine waypoints."$(name)" run tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.exp.no_waypoint","color":"red"},{"text":"$(name)","color":"aqua"}]
$execute unless data storage macroengine:engine waypoints."$(name)" run return 0

$tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.exp.teleporting","color":"gray"},{"text":"$(name)","color":"aqua"}]
$function macroengine:core/internal/experimental/waypoint/do_tp with storage macroengine:engine waypoints.$(name)
