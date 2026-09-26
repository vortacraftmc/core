$execute if data storage macroengine:engine schedules.$(key) run data remove storage macroengine:engine schedules.$(key)

$data modify storage macroengine:engine schedules.$(key).func set value "$(func)"
$data modify storage macroengine:engine schedules.$(key).interval set value $(interval)
$data modify storage macroengine:engine queue append value {func:"$(func)", delay:$(interval)}
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_schedule","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(key)","color":"aqua"}]
