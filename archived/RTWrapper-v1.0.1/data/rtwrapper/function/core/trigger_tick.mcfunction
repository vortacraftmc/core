# Polls every registered trigger objective for every online player once per tick,
# firing enabled ones whose score is non-zero for that player, then applying reset_mode.
# vc-gate: inert until rtwrapper:gate/v1_0_1 state is active
execute unless data storage rtwrapper:gate/v1_0_1 {state:"active"} run return 0
execute if data storage rtwrapper:triggers registry[0] as @a at @s run data modify storage rtwrapper:runtime trigger_poll set value {index:0}
execute if data storage rtwrapper:triggers registry[0] as @a at @s run function rtwrapper:core/trigger/poll_step with storage rtwrapper:runtime trigger_poll
