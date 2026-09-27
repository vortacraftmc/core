# macroengine:core/internal/load/unsupported_gate
#
# macroEngine v26.3 (vortacraftmc/core, tickwarden-patch-1) is UNSUPPORTED.
# No new features or fixes are planned for this pack. Development has moved
# to dataLib-dp: https://github.com/runtoolkit/dataLib-dp
# (v26.4 is a separate, still-supported pack — this gate does not apply to it.)
#
# Called by core/internal/load/main and core/internal/load/force_apply
# before either is allowed to run the full engine init pipeline
# (core/internal/load/all). Blocks by default — an admin must opt in
# explicitly via macroengine:engine config.allow_unsupported_load.
#
# OUTPUT: returns 1 if the caller may proceed with a full init, 0 if the
# caller must stop (engine stays uninitialized; static data such as
# recipes/loot_tables/advancements/predicates is unaffected either way).

tellraw @s ["",{"translate":"macroengine.prefix","color":"red","bold":true},{"translate":"macroengine.load.unsupported","color":"red","bold":true},{"translate":"macroengine.load.unsupported.body","color":"yellow"},{"translate":"macroengine.load.unsupported.link","color":"aqua","underlined":true,"click_event":{"action":"open_url","url":"https://github.com/runtoolkit/dataLib-dp"}},{"translate":"macroengine.load.unsupported.override_prefix","color":"yellow"},{"translate":"macroengine.cmd.allow_unsupported_load","color":"gray","click_event":{"action":"suggest_command","command":"/data modify storage macroengine:engine config.allow_unsupported_load set value 1b"}}]

execute if data storage macroengine:engine config{allow_unsupported_load:1b} run return 1
return 0
