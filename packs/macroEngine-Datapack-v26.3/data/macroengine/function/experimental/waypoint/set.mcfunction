# macroengine:experimental/waypoint/set [MACRO]
# Stores a named waypoint at the caller's current position.
# Gated behind flags.experimental.waypoint.
#
# Usage:  function macroengine:experimental/waypoint/set {name:"base"}
# Caller: any player

execute unless data storage macroengine:engine flags.experimental{waypoint:1b} run tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.exp.waypoint_disabled","color":"red"}]
execute unless data storage macroengine:engine flags.experimental{waypoint:1b} run return 0

data modify storage macroengine:engine _waypoint_tmp set value {}
execute store result storage macroengine:engine _waypoint_tmp.x int 1 run data get entity @s Pos[0]
execute store result storage macroengine:engine _waypoint_tmp.y int 1 run data get entity @s Pos[1]
execute store result storage macroengine:engine _waypoint_tmp.z int 1 run data get entity @s Pos[2]
data modify storage macroengine:engine _waypoint_tmp.dimension set from entity @s Dimension

execute unless data storage macroengine:engine waypoints run data modify storage macroengine:engine waypoints set value {}
$data modify storage macroengine:engine waypoints."$(name)" set from storage macroengine:engine _waypoint_tmp
data remove storage macroengine:engine _waypoint_tmp

$tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.exp.waypoint_label","color":"gray"},{"text":"$(name)","color":"aqua"},{"translate":"macroengine.exp.waypoint_set","color":"green"}]
