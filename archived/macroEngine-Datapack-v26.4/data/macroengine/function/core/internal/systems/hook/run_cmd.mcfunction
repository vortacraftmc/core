# macroengine:systems/hook/internal/run_cmd [MACRO]
# INPUT: $(cmd)
# @s = the triggering player
# No permission gate — runs $(cmd) unconditionally, debug tag only logs it.
# vc-gate: sink guard, disabled unless macroengine:gate/v26_4 state is active
execute unless data storage macroengine:gate/v26_4 {state:"active"} run return fail
$$(cmd)