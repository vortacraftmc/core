# ─────────────────────────────────────────────────────────────────
# macroengine:api/cmd/other/multi_cmd/advanced/internal/run_spread
# Spreads _mcmd_queue execution: one item per tick.
# Schedules run_spread_tick which self-reschedules until queue is drained.
# Supports full item format (conditions, hooks, cmd, func).
# ─────────────────────────────────────────────────────────────────

execute if data storage macroengine:engine _mcmd_queue[0] run schedule function macroengine:core/internal/api/cmd/other/multi_cmd/advanced/run_spread_tick 1t append

# # tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.multi_cmd_run_spread","color":"aqua"},{"translate":"macroengine.debug.spread_sched","color":"gray"}]
