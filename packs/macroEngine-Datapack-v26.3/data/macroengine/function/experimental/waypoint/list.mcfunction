# macroengine:experimental/waypoint/list
# Prints all stored waypoint names.
#
# Usage:  function macroengine:experimental/waypoint/list
# Caller: any player

execute unless data storage macroengine:engine flags.experimental{waypoint:1b} run tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.exp.waypoint_disabled","color":"red"}]
execute unless data storage macroengine:engine flags.experimental{waypoint:1b} run return 0

tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.header.waypoints","color":"#555555"}]
execute unless data storage macroengine:engine waypoints run tellraw @s ["",{"translate":"macroengine.waypoint.none","color":"gray","italic":true}]
tellraw @s ["",{"text":" ","color":"#555555"},{"plain":true,"storage":"macroengine:engine","nbt":"waypoints","interpret":false,"color":"yellow"}]
tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.ui.sep29","color":"#555555"}]
