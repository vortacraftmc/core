# ─────────────────────────────────────────────────────────────────
# macroengine:api/cmd/other/multi_cmd/debug
# Diagnostics for one queue entry. Reports, in order:
#
#   1. shape    — is the entry a compound, and does it carry `condition`?
#   2. subject  — is @s a player? tag/score/entity/predicate leaves all
#                 evaluate against @s, so from a command block or the
#                 console @s matches nothing and those leaves report
#                 not-passed. This is the single most common reason a
#                 condition blocks everything.
#   3. verdict  — what the evaluator actually wrote to $mcmd_cond_result,
#                 including the case where it wrote nothing at all
#   4. body     — did the execution half actually run?
#
# INPUT (storage macroengine:input): entry — the queue entry to diagnose
#
# Usage, from chat as a player:
#   data modify storage macroengine:input entry set value {cmd:"data modify storage macroengine:engine _dbg_ran set value 1",condition:{tag:"vip"}}
#   function macroengine:api/cmd/other/multi_cmd/debug
#
# Then run the SAME two lines from a command block and compare. If the
# verdict differs, the execution subject is the cause.
# ─────────────────────────────────────────────────────────────────

tellraw @s [{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"━━━ multi_cmd debug ━━━","color":"#555555"}]

tellraw @s [{"text":"  entry ","color":"gray"},{"text":"→ ","color":"#555555"},{"plain":true,"interpret":false,"storage":"macroengine:input","nbt":"entry","color":"yellow"}]

execute unless data storage macroengine:input entry run tellraw @s [{"text":"  ERROR ","color":"red","bold":true},{"text":"macroengine:input entry is not set","color":"red"}]
execute unless data storage macroengine:input entry run return 0

# --- 1. shape ------------------------------------------------------
execute if data storage macroengine:input entry{} run tellraw @s [{"text":"  shape ","color":"gray"},{"text":"→ compound","color":"green"}]
execute unless data storage macroengine:input entry{} run tellraw @s [{"text":"  shape ","color":"gray"},{"text":"→ plain string. A string entry cannot carry a condition; wrap it as {cmd:\"...\"}.","color":"red"}]

execute if data storage macroengine:input entry.condition run tellraw @s [{"text":"  condition ","color":"gray"},{"text":"→ detected","color":"green"}]
execute unless data storage macroengine:input entry.condition run tellraw @s [{"text":"  condition ","color":"gray"},{"text":"→ none, so this entry always runs","color":"yellow"}]

# --- 2. execution subject -----------------------------------------
execute if entity @s[type=minecraft:player] run tellraw @s [{"text":"  @s ","color":"gray"},{"text":"→ player","color":"green"}]
execute unless entity @s[type=minecraft:player] run tellraw @s [{"text":"  @s ","color":"gray"},{"text":"→ NOT a player. tag/score/entity/predicate evaluate against @s and will report not-passed. Prefix with: execute as @p at @s run ...","color":"red"}]

# --- 3. the verdict, straight from the evaluator -------------------
data modify storage macroengine:engine _mcmd_current set from storage macroengine:input entry
scoreboard players reset $dbg_set macroengine.tmp

execute unless data storage macroengine:engine _mcmd_current.condition run tellraw @s [{"text":"  verdict ","color":"gray"},{"text":"→ n/a (no condition)","color":"yellow"}]

execute if data storage macroengine:engine _mcmd_current.condition run function macroengine:core/internal/api/cmd/other/multi_cmd/check_condition
execute if data storage macroengine:engine _mcmd_current.condition store success score $dbg_set macroengine.tmp if score $mcmd_cond_result macroengine.tmp matches -2147483648..2147483647

execute if data storage macroengine:engine _mcmd_current.condition if score $dbg_set macroengine.tmp matches 0 run tellraw @s [{"text":"  verdict ","color":"gray"},{"text":"→ UNSET. check_condition never wrote $mcmd_cond_result. Confirm the objective exists (scoreboard objectives list) and that cond_eval_core is present in this build.","color":"red"}]
execute if data storage macroengine:engine _mcmd_current.condition if score $mcmd_cond_result macroengine.tmp matches 1 run tellraw @s [{"text":"  verdict ","color":"gray"},{"text":"→ 1 (passed)","color":"green"}]
execute if data storage macroengine:engine _mcmd_current.condition if score $dbg_set macroengine.tmp matches 1 if score $mcmd_cond_result macroengine.tmp matches 0 run tellraw @s [{"text":"  verdict ","color":"gray"},{"text":"→ 0 (not passed)","color":"red"}]

# show the leaf that produced the 0, so it can be narrowed without guessing
execute if data storage macroengine:engine _mcmd_current.condition if score $dbg_set macroengine.tmp matches 1 if score $mcmd_cond_result macroengine.tmp matches 0 run tellraw @s [{"text":"  leaves ","color":"gray"},{"text":"→ ","color":"#555555"},{"plain":true,"interpret":false,"storage":"macroengine:engine","nbt":"_mcmd_current.condition","color":"red"}]

# --- 4. did the body run? ------------------------------------------
data remove storage macroengine:engine _dbg_ran
data modify storage macroengine:engine _mcmd_queue set value []
data modify storage macroengine:engine _mcmd_queue append from storage macroengine:input entry
data modify storage macroengine:engine _mcmd_options set value {error_mode:"continue",profile:0b,spread:0}
function macroengine:api/cmd/other/multi_cmd/run

execute if data storage macroengine:engine _dbg_ran run tellraw @s [{"text":"  body ","color":"gray"},{"text":"→ RAN","color":"green"}]
execute unless data storage macroengine:engine _dbg_ran run tellraw @s [{"text":"  body ","color":"gray"},{"text":"→ did NOT run","color":"red"}]

tellraw @s [{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"`body` only reads RAN when the entry's cmd writes _dbg_ran — use cmd:\"data modify storage macroengine:engine _dbg_ran set value 1\" to measure the gate itself.","color":"gray","italic":true}]
tellraw @s [{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━","color":"#555555"}]

data remove storage macroengine:engine _mcmd_current
data remove storage macroengine:engine _dbg_ran
scoreboard players reset $dbg_set macroengine.tmp
