# macroengine:api/cmd/other/multi_cmd [MACRO]
# Executes a list of commands in order.
# INPUT (macro args): $(commands) — list of command strings/objects
#

$data modify storage macroengine:engine _mcmd_queue set value $(commands)
data modify storage macroengine:engine _mcmd_options set value {error_mode:"continue",profile:0b,spread:0}

execute at @s run function macroengine:api/cmd/other/multi_cmd/run
