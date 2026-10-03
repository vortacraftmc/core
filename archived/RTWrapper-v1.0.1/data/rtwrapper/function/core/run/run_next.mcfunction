# Processes exactly one action: queued request first, otherwise one direct api request.
# vc-gate: inert until rtwrapper:gate/v1_0_1 state is active
execute unless data storage rtwrapper:gate/v1_0_1 {state:"active"} run return 0
execute if score #debug rtw.config matches 1.. if score #silent rtw.config matches 0 run tellraw @a[tag=rtwrapper.debug] [{"text":"[RTWrapper] run_next","color":"gold"}]
function rtwrapper:core/wrappers/handler/main
