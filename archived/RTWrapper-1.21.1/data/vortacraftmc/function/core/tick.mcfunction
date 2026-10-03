# vortacraftmc shared registry tick hook. Currently a no-op: the loaded-pack registry is
# advancement-based (see core/load.mcfunction) and does not need per-tick work. Kept as a
# tag target so other vortacraftmc datapacks can extend #vortacraftmc tick behavior later
# without needing to touch minecraft:tick_functions.
# vc-gate: inert until rtwrapper:gate/r1_21_1 state is active
execute unless data storage rtwrapper:gate/r1_21_1 {state:"active"} run return 0
