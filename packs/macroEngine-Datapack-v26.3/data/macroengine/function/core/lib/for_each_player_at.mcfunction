$data modify storage macroengine:engine _dispatch.func set value "$(func)"
execute as @a at @s run function #macroengine:internal/dispatch
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_for_each_player_at","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(func)","color":"aqua"}]
