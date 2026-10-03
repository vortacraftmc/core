# rtwrapper:gate/r26_3/confirm - operator confirmation (Gate 1 version/format + Gate 2 confirm)
# Usage: /function rtwrapper:gate/r26_3/confirm {format:107}
# Players need the tag first; the console and command blocks have no entity and pass.
execute if data storage rtwrapper:gate/r26_3 {state:"locked"} run return run say [RTWrapper] confirm refused: pack is LOCKED. Use rtwrapper:gate/r26_3/unlock first.
execute if entity @s[type=player] unless entity @s[tag=rtwrapper.gate_admin] run return run say [RTWrapper] confirm refused: executor needs the tag rtwrapper.gate_admin
$data modify storage rtwrapper:gate/r26_3 input set value {format:$(format)}
execute unless data storage rtwrapper:gate/r26_3 {input:{format:107}} run return run say [RTWrapper] confirm refused: format mismatch - this build targets data pack format 107
data remove storage rtwrapper:gate/r26_3 input
data modify storage rtwrapper:gate/r26_3 confirmed set value "v1.0.0"
data modify storage rtwrapper:gate/r26_3 state set value "active"
execute if entity @s[type=player] run tag @s remove rtwrapper.gate_admin
say [RTWrapper] confirmed for v1.0.0 (format 107). Initialising.
function rtwrapper:core/load
function rtwrapper:core/trigger_load
