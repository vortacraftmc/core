# macro: $(cmd)     stored by an operator; runs at function permission level
# vc-gate: sink guard, disabled unless guikit:gate/v5 state is active
execute unless data storage guikit:gate/v5 {state:"active"} run return fail
$execute as @s at @s run $(cmd)
