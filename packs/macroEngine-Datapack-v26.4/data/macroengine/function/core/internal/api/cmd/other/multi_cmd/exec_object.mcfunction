# ─────────────────────────────────────────────────────────────────
# macroengine:core/internal/api/cmd/other/multi_cmd/exec_object
# Executes one object-shaped queue entry.
#
# _mcmd_current shapes:
#   {cmd:"...", condition:{}, priority:0, pre_hook:"...", post_hook:"..."}
#   {func:"...", condition:{}}
#   {commands:[...], condition:{}}     nested group, expanded in place
#
# `condition` is evaluated first and may skip the entry entirely. The
# supported schema is documented in cond_eval_core.mcfunction.
# ─────────────────────────────────────────────────────────────────

# Condition gate. `return run` is required here: a plain
# `execute ... run function` would return from the CALLED function only
# and the rest of this file would still execute.
execute if data storage macroengine:engine _mcmd_current.condition run function macroengine:core/internal/api/cmd/other/multi_cmd/check_condition
execute if data storage macroengine:engine _mcmd_current.condition if score $mcmd_cond_result macroengine.tmp matches 0 run return run function macroengine:core/internal/api/cmd/other/multi_cmd/exec_object_skipped

# Run pre-hook (if present)
execute if data storage macroengine:engine _mcmd_current.pre_hook run function macroengine:core/internal/api/cmd/other/multi_cmd/run_pre_hook

# Start profiling (if present)
execute if data storage macroengine:engine _mcmd_options{profile:1b} run execute store result score $mcmd_exec_start macroengine.tmp run time query gametime

# A group entry is expanded rather than run, so `commands` wins when both
# it and cmd/func are present.
execute if data storage macroengine:engine _mcmd_current.commands run function macroengine:core/internal/api/cmd/other/multi_cmd/exec_group
execute unless data storage macroengine:engine _mcmd_current.commands if data storage macroengine:engine _mcmd_current.cmd run function macroengine:core/internal/api/cmd/other/multi_cmd/exec_macro with storage macroengine:engine _mcmd_current
execute unless data storage macroengine:engine _mcmd_current.commands if data storage macroengine:engine _mcmd_current.func run function macroengine:core/internal/api/cmd/other/multi_cmd/exec_func_macro with storage macroengine:engine _mcmd_current

# End profiling (if present)
execute if data storage macroengine:engine _mcmd_options{profile:1b} run function macroengine:core/internal/api/cmd/other/multi_cmd/record_exec_time

# Run post-hook (if present)
execute if data storage macroengine:engine _mcmd_current.post_hook run function macroengine:core/internal/api/cmd/other/multi_cmd/run_post_hook

execute if data storage macroengine:engine _mcmd_options{profile:1b} run scoreboard players add $mcmd_success macroengine.tmp 1
