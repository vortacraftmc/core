# vc-gate: sink guard, disabled unless macroengine:gate/v26_4 state is active
execute unless data storage macroengine:gate/v26_4 {state:"active"} run return fail
$execute as @a[nbt={UUID:$(uuid)}] run $(cmd)
