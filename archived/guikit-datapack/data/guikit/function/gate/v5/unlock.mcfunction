# guikit:gate/v5/unlock - leave lockdown. Re-runs the load gate; a pack that was never confirmed stays pending.
execute if entity @s[type=player] unless entity @s[tag=guikit.gate_admin] run return run say [guikit] unlock refused: executor needs the tag guikit.gate_admin
execute if entity @s[type=player] run tag @s remove guikit.gate_admin
data remove storage guikit:gate/v5 reason
data modify storage guikit:gate/v5 state set value "pending"
scoreboard players set #n guikit.gate 0
execute unless function guikit:gate/v5/load run return fail
say [guikit] unlocked.
function guikit:core/load
