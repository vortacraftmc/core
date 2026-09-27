# macroengine:api/cmd/other/multi_cmd [MACRO]
# Executes a list of commands in order.
# INPUT (macro args): $(commands) — list of command strings/objects
#

$data modify storage macroengine:engine _mcmd_queue set value $(commands)
data modify storage macroengine:engine _mcmd_options set value {error_mode:"continue",profile:0b,spread:0}

execute at @s run function macroengine:api/cmd/other/multi_cmd/run
# # tellraw @a[tag=macroengine.debug] ["",{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"cmd/other/multi_cmd ","color":"aqua"},{"text":"▶ executing batch","color":"#555555"}]

# Clear type marker
data remove storage macroengine:engine multiCommands.type
data remove storage macroengine:engine multiCommands.active
