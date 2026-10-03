# rtwrapper:gate/v1_0_1/confirm - operator confirmation (Gate 1 version/format + Gate 2 confirm)
# Usage: /function rtwrapper:gate/v1_0_1/confirm {format:122}
# Players need the tag first; the console and command blocks have no entity and pass.
execute if data storage rtwrapper:gate/v1_0_1 {state:"locked"} run return run say [RTWrapper] confirm refused: pack is LOCKED. Use rtwrapper:gate/v1_0_1/unlock first.
execute if entity @s[type=player] unless entity @s[tag=rtwrapper.gate_admin] run return run say [RTWrapper] confirm refused: executor needs the tag rtwrapper.gate_admin
$data modify storage rtwrapper:gate/v1_0_1 input set value {format:$(format)}
execute unless data storage rtwrapper:gate/v1_0_1 {input:{format:122}} run return run say [RTWrapper] confirm refused: format mismatch - this build targets data pack format 122
data remove storage rtwrapper:gate/v1_0_1 input
data modify storage rtwrapper:gate/v1_0_1 confirmed set value "v1.0.1"
data modify storage rtwrapper:gate/v1_0_1 state set value "active"
execute if entity @s[type=player] run tag @s remove rtwrapper.gate_admin
say [RTWrapper] confirmed for v1.0.1 (format 122). Initialising.
function rtwrapper:core/load
function rtwrapper:core/trigger_load
