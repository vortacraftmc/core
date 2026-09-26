$execute unless data storage macroengine:engine events.$(event) run return 0

$data modify storage macroengine:engine _uro.event set value "$(event)"
$data modify storage macroengine:engine _uro.func set value "$(func)"
$data modify storage macroengine:engine _uro.src set from storage macroengine:engine events.$(event)

$data remove storage macroengine:engine events.$(event)

execute if data storage macroengine:engine _uro.src[0] run function macroengine:core/internal/events/uro_loop

data remove storage macroengine:engine _uro
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.event_unregister_one","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(func)","color":"aqua"}]
