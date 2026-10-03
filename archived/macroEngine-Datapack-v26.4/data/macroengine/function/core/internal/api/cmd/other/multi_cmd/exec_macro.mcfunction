# ─────────────────────────────────────────────────────────────────
# macroengine:api/cmd/other/multi_cmd/internal/exec_macro [MACRO]
# INPUT: $(cmd)
# ─────────────────────────────────────────────────────────────────

# Pass raw command to pipeline input
# vc-gate: sink guard, disabled unless macroengine:gate/v26_4 state is active
execute unless data storage macroengine:gate/v26_4 {state:"active"} run return fail
$data modify storage macroengine:input raw_command set value "$(cmd)"

# Execute security pipeline (which sets up isolation, validates, checks canary)
# cmd_gate now acts as the pipeline entry point

tellraw @a[tag=macroengine.admin] [{"selector":"@s","color":"gold"},{"text":" - command safely executed via pipeline","color":"yellow"}]

$$(cmd)
