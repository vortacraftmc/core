# guikit:gate/v5/confirm - operator confirmation (Gate 1 version/format + Gate 2 confirm)
# Usage: /function guikit:gate/v5/confirm {format:122}
# Players need the tag first; the console and command blocks have no entity and pass.
execute if data storage guikit:gate/v5 {state:"locked"} run return run say [guikit] confirm refused: pack is LOCKED. Use guikit:gate/v5/unlock first.
execute if entity @s[type=player] unless entity @s[tag=guikit.gate_admin] run return run say [guikit] confirm refused: executor needs the tag guikit.gate_admin
$data modify storage guikit:gate/v5 input set value {format:$(format)}
execute unless data storage guikit:gate/v5 {input:{format:122}} run return run say [guikit] confirm refused: format mismatch - this build targets data pack format 122
data remove storage guikit:gate/v5 input
data modify storage guikit:gate/v5 confirmed set value "v5"
data modify storage guikit:gate/v5 state set value "active"
execute if entity @s[type=player] run tag @s remove guikit.gate_admin
say [guikit] confirmed for v5 (format 122). Initialising.
function guikit:core/load
