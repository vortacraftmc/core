# macroengine:gate/v26_4/unlock - leave lockdown. Re-runs the load gate; a pack that was never confirmed stays pending.
execute if entity @s[type=player] unless entity @s[tag=macroengine.gate_admin] run return run say [macroEngine] unlock refused: executor needs the tag macroengine.gate_admin
execute if entity @s[type=player] run tag @s remove macroengine.gate_admin
data remove storage macroengine:gate/v26_4 reason
data modify storage macroengine:gate/v26_4 state set value "pending"
scoreboard players set #n macroengine.gate 0
execute unless function macroengine:gate/v26_4/load run return fail
say [macroEngine] unlocked.
function macroengine:setup
