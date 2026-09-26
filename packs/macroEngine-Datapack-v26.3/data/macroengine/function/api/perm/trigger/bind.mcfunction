$scoreboard objectives add $(name) trigger

$execute unless data storage macroengine:engine perm_triggers.$(name) run data modify storage macroengine:engine perm_triggers.$(name) set value []
$data modify storage macroengine:engine perm_triggers.$(name) append value {value:$(value), func:"$(func)", perm:"$(perm)"}

execute unless data storage macroengine:engine perm_trigger_names run data modify storage macroengine:engine perm_trigger_names set value []
$execute unless data storage macroengine:engine perm_trigger_names[{name:"$(name)"}] run data modify storage macroengine:engine perm_trigger_names append value {name:"$(name)"}

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.perm_trigger_bind","color":"aqua"},{"text":"✔ ","color":"green"},{"text":"$(name)","color":"white"},{"text":":","color":"#555555"},{"text":"$(value)","color":"yellow"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(func)","color":"aqua"},{"text":" [","color":"#555555"},{"text":"$(perm)","color":"green"},{"text":"]","color":"#555555"}]
