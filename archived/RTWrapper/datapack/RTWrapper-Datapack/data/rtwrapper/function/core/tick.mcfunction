# Disabled by default. Enable with: function rtwrapper:api/autotick/on
# Autotick intentionally processes only one action per tick. Use rtwrapper:api/run
# when you explicitly want to drain the whole queue immediately.
# vc-gate: inert until rtwrapper:gate/r26_3 state is active
execute unless data storage rtwrapper:gate/r26_3 {state:"active"} run return 0
execute if score #auto_tick rtw.config matches 1.. run function rtwrapper:core/run/run_next
