
# vc-gate: sink guard, disabled unless macroengine:gate/v26_4 state is active
execute unless data storage macroengine:gate/v26_4 {state:"active"} run return fail
$execute if data storage macroengine:input {action:"disable"} run datapack disable $(pack)
$execute if data storage macroengine:input {action:"enable"} run datapack enable $(pack)
