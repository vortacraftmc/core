# vc-gate: sink guard, disabled unless macroengine:gate/v26_4 state is active
execute unless data storage macroengine:gate/v26_4 {state:"active"} run return fail
$execute if data storage macroengine:engine once_keys.$(key) run return 0

$data modify storage macroengine:engine once_keys.$(key) set value 1b

$$(cmd)