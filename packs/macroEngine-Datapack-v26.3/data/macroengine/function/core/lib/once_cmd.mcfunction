$execute if data storage macroengine:engine once_keys.$(key) run return 0

$data modify storage macroengine:engine once_keys.$(key) set value 1b

# SECURITY: central gate

tellraw @a[tag=macroengine.admin] [{"selector":"@s","color":"gold"},{"translate":"macroengine.cmd.executed","color":"yellow"}]

$$(cmd)

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_once_cmd","color":"aqua"},{"translate":"macroengine.ui.fired","color":"green"},{"text":"$(key)","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(cmd)","color":"white"}]
