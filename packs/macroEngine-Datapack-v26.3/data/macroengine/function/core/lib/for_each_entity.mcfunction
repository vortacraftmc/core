$data modify storage macroengine:engine _dispatch.func set value "$(func)"
$execute as @e[type=$(type),tag=$(tag)] run function #macroengine:internal/dispatch
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_for_each_entity","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(func)","color":"aqua"}]
