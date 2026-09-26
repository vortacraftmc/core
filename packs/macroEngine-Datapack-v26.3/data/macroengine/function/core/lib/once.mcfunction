$execute if data storage macroengine:engine once_keys.$(key) run return 0

$data modify storage macroengine:engine once_keys.$(key) set value 1b

$data modify storage macroengine:engine _dispatch.func set value "$(func)"
function #macroengine:internal/dispatch

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_once","color":"aqua"},{"translate":"macroengine.ui.fired","color":"green"},{"text":"$(key)","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(func)","color":"white"}]
