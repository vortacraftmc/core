execute unless data storage macroengine:engine trigger_binds run data modify storage macroengine:engine trigger_binds set value []

$data modify storage macroengine:engine trigger_binds append value {value:$(value), cmd:"$(cmd)"}
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.trigger_bind_cmd","color":"aqua"},{"text":"✔ ","color":"green"},{"text":"$(value)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(cmd)","color":"aqua"}]
