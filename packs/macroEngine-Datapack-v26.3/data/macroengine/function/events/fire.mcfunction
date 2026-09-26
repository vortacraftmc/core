# # $execute unless data storage macroengine:engine events.$(event) run execute as @a[tag=macroengine.debug] run tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.event_fire","color":"aqua"},{"translate":"macroengine.ui.skip","color":"#FF5555"},{"text":"$(event)","color":"#AAAAAA"},{"translate":"macroengine.debug.no_handlers","color":"#555555"}]
$execute unless data storage macroengine:engine events.$(event) run return 0

$data modify storage macroengine:engine _event_tmp set from storage macroengine:engine events.$(event)
execute if data storage macroengine:engine _event_tmp[0] run function macroengine:core/internal/events/fire_next
data remove storage macroengine:engine _event_tmp
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.event_fire","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(event)","color":"aqua"}]
