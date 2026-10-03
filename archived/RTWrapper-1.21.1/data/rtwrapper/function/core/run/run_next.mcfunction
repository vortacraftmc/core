# Process exactly one queued/direct action, then return. Queue takes priority
# over a direct rtwrapper:api request (see core/wrappers/handler/main). Called
# by core/tick.mcfunction under autotick, and once per action by run_actions.
# vc-gate: inert until rtwrapper:gate/r1_21_1 state is active
execute unless data storage rtwrapper:gate/r1_21_1 {state:"active"} run return 0
function rtwrapper:core/wrappers/handler/main
