# Kick: applies immediately — no permission check.
#
# INPUT : $(player) -> exact player name, $(reason) -> kick reason
# vc-gate: sink guard, disabled unless macroengine:gate/v26_4 state is active
execute unless data storage macroengine:gate/v26_4 {state:"active"} run return fail
$function macroengine:core/internal/cmd/kick_apply {player:"$(player)",reason:"$(reason)"}
