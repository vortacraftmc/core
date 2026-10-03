# RTWrapper trigger-module bootstrap. Idempotent - safe to call every /reload.
# vc-gate: inert until rtwrapper:gate/r26_3 state is active
execute unless data storage rtwrapper:gate/r26_3 {state:"active"} run return 0
scoreboard objectives add rtw.status dummy
execute unless data storage rtwrapper:triggers registry run data modify storage rtwrapper:triggers registry set value []
