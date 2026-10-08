# ─────────────────────────────────────────────────────────────────
# macroengine:core/internal/api/cmd/other/multi_cmd/cond_any_loop [MACRO]
# INPUT: $(d) — nesting depth. Consumes _mcmd_any_list_<d> one child at a
# time and stops as soon as one child passes.
# ─────────────────────────────────────────────────────────────────

$execute unless data storage macroengine:engine _mcmd_any_list_$(d)[0] run return 0
$execute if score $mcmd_any_pass_$(d) macroengine.tmp matches 1 run return 0

$data modify storage macroengine:engine _mcmd_cond_eval set from storage macroengine:engine _mcmd_any_list_$(d)[0]
$data remove storage macroengine:engine _mcmd_any_list_$(d)[0]

function macroengine:core/internal/api/cmd/other/multi_cmd/cond_eval_core

$execute if score $mcmd_cond_result macroengine.tmp matches 1 run scoreboard players set $mcmd_any_pass_$(d) macroengine.tmp 1

function macroengine:core/internal/api/cmd/other/multi_cmd/cond_any_loop with storage macroengine:engine _mcmd_depth_arg
