
# DL - Universal World Clock Controller
# Usage: /function ame:clock_handler {clock:"macroengine:test", action:"set", value:"12000"}
$time of $(clock) $(action) $(value)

# System Debug Log for staff (Only for users with 'macroengine.debug' tag)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.clock_system_update","color":"aqua"},{"text":"$(clock) ","color":"white"},{"translate":"macroengine.fmt.action","color":"gray"},{"text":"$(action) ","color":"gold"},{"translate":"macroengine.fmt.value","color":"gray"},{"text":"$(value)","color":"yellow"}]
