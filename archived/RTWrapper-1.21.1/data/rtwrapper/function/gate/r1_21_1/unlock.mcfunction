# rtwrapper:gate/r1_21_1/unlock - leave lockdown. Re-runs the load gate; a pack that was never confirmed stays pending.
execute if entity @s[type=player] unless entity @s[tag=rtwrapper.gate_admin] run return run say [RTWrapper] unlock refused: executor needs the tag rtwrapper.gate_admin
execute if entity @s[type=player] run tag @s remove rtwrapper.gate_admin
data remove storage rtwrapper:gate/r1_21_1 reason
data modify storage rtwrapper:gate/r1_21_1 state set value "pending"
scoreboard players set #n rtwrapper.gate 0
execute unless function rtwrapper:gate/r1_21_1/load run return fail
say [RTWrapper] unlocked.
function vortacraftmc:core/load
function rtwrapper:core/load
function rtwrapper:core/trigger_load
