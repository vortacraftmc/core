# macroengine:gate/v26_4/confirm - operator confirmation (Gate 1 version/format + Gate 2 confirm)
# Usage: /function macroengine:gate/v26_4/confirm {format:122}
# Players need the tag first; the console and command blocks have no entity and pass.
execute if data storage macroengine:gate/v26_4 {state:"locked"} run return run say [macroEngine] confirm refused: pack is LOCKED. Use macroengine:gate/v26_4/unlock first.
execute if entity @s[type=player] unless entity @s[tag=macroengine.gate_admin] run return run say [macroEngine] confirm refused: executor needs the tag macroengine.gate_admin
$data modify storage macroengine:gate/v26_4 input set value {format:$(format)}
execute unless data storage macroengine:gate/v26_4 {input:{format:122}} run return run say [macroEngine] confirm refused: format mismatch - this build targets data pack format 122
data remove storage macroengine:gate/v26_4 input
data modify storage macroengine:gate/v26_4 confirmed set value "v26.4-snapshot-1"
data modify storage macroengine:gate/v26_4 state set value "active"
execute if entity @s[type=player] run tag @s remove macroengine.gate_admin
say [macroEngine] confirmed for v26.4-snapshot-1 (format 122). Initialising.
function macroengine:setup
