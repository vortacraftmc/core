$data modify storage macroengine:engine event_context.player set value "$(player)"

function macroengine:events/fire with storage macroengine:input {}

data remove storage macroengine:engine event_context.player

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.event_fire_as","color":"aqua"},{"text":"$(event)","color":"aqua"},{"translate":"macroengine.ui.as","color":"#555555"},{"text":"$(player)","color":"white"}]
