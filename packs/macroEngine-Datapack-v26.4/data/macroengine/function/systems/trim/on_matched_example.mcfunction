# ======================================================================================
# macroengine:systems/trim/on_matched_example
# ======================================================================================
# EXAMPLE hook handler for the "macroengine:trim_matched" event fired by
# systems/trim/_private/fire_matched. Not bound automatically — this is a
# template showing how to react to trim/scan results; register it yourself
# with:
#
#   data modify storage macroengine:input event set value "macroengine:trim_matched"
#   data modify storage macroengine:input func set value "macroengine:systems/trim/on_matched_example"
#   function macroengine:systems/hook/bind
#
# Runs as the player being scanned (see fire_matched → events/fire → the
# hook system executes bound funcs as the context player). Reads the
# matched slot back out of event_context and gives simple feedback.
# ======================================================================================

execute unless entity @s run return fail

data modify storage macroengine:engine _sound set value {sound:"",category:"player",target:"",volume:0.0f,pitch:0.4f}
data modify storage macroengine:input _sound.sound set from storage macroengine:input sound
data modify storage macroengine:input _sound.category set from storage macroengine:input category
data modify storage macroengine:input _sound.target set from storage macroengine:input target
data modify storage macroengine:input _sound.volume set from storage macroengine:input volume
data modify storage macroengine:input _sound.volume set from storage macroengine:input pitch

function macroengine:systems/sound/play with storage macroengine:engine _sound
data remove storage macroengine:engine _sound

execute if data storage macroengine:engine event_context.slot run tellraw @s ["",{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"Circuit trim (Overload) detected on ","color":"aqua"},{"nbt":"event_context.slot","storage":"macroengine:engine","color":"white","plain":true,"interpret":false},{"text":" slot.","color":"aqua"}]