$data modify storage macroengine:engine _dispatch.func set value "$(func)"
$execute as @a[distance=..$(distance),limit=1,sort=nearest] at @s run function #macroengine:internal/dispatch
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.geo_as_nearby_player","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(func)","color":"aqua"}]
