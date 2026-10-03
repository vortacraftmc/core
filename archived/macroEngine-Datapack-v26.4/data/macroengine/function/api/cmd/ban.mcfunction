# Ban: applies immediately — no permission check.
#
# INPUT : $(player) -> exact player name, $(reason) -> ban reason
# vc-gate: sink guard, disabled unless macroengine:gate/v26_4 state is active
execute unless data storage macroengine:gate/v26_4 {state:"active"} run return fail
$function macroengine:core/internal/cmd/ban_apply {player:"$(player)",reason:"$(reason)"}
