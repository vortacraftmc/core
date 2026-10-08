# ─────────────────────────────────────────────────────────────────
# macroengine:api/cmd/other/multi_cmd/selftest
# In-game check that the condition gate actually gates.
#
# Run this AS A PLAYER:
#     execute as <player> at @s run function macroengine:api/cmd/other/multi_cmd/selftest
#
# Every case below states up front whether the entry should run or be
# skipped, and the harness only believes the observable result (whether
# _selftest_ran got set). A case that reports FAIL means the verdict and
# the behaviour disagree — i.e. the gate is being bypassed.
#
# Results are written to macroengine:output selftest.
# ─────────────────────────────────────────────────────────────────

execute unless entity @s[type=minecraft:player] run tellraw @a[tag=macroengine.admin] [{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"selftest must run as a player","color":"red"}]
execute unless entity @s[type=minecraft:player] run return 0

scoreboard players set $selftest_pass macroengine.tmp 0
scoreboard players set $selftest_fail macroengine.tmp 0

# --- fixtures -------------------------------------------------------
tag @s add macroengine_selftest
scoreboard players set @s macroengine.tmp 5
data modify storage macroengine:engine _selftest_val set value 7

tellraw @s [{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"━━━ multi_cmd condition selftest ━━━","color":"#555555"}]

# --- 1. no condition: must always run -------------------------------
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"no-condition runs",expect:1,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1"}}

# --- 2. tag leaf ----------------------------------------------------
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"tag present -> run",expect:1,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{tag:"macroengine_selftest"}}}
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"tag absent -> skip",expect:0,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{tag:"macroengine_selftest_absent_xyz"}}}
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"tag has:0b absent -> run",expect:1,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{tag:{name:"macroengine_selftest_absent_xyz",has:0b}}}}
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"tag has:0b present -> skip",expect:0,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{tag:{name:"macroengine_selftest",has:0b}}}}

# --- 3. score leaf --------------------------------------------------
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"score in range -> run",expect:1,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{score:{objective:"macroengine.tmp",min:5,max:5}}}}
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"score out of range -> skip",expect:0,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{score:{objective:"macroengine.tmp",min:6}}}}

# --- 4. data leaf ---------------------------------------------------
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"data in range -> run",expect:1,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{data:{storage:"macroengine:engine",path:"_selftest_val",min:1,max:10}}}}
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"data out of range -> skip",expect:0,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{data:{storage:"macroengine:engine",path:"_selftest_val",min:100,max:200}}}}
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"data missing path -> skip",expect:0,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{data:{storage:"macroengine:engine",path:"_selftest_does_not_exist"}}}}

# --- 5. composition -------------------------------------------------
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"all_of both true -> run",expect:1,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{all_of:[{tag:"macroengine_selftest"},{score:{objective:"macroengine.tmp",min:5,max:5}}]}}}
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"all_of one false -> skip",expect:0,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{all_of:[{tag:"macroengine_selftest"},{tag:"macroengine_selftest_absent_xyz"}]}}}
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"any_of one true -> run",expect:1,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{any_of:[{tag:"macroengine_selftest_absent_xyz"},{tag:"macroengine_selftest"}]}}}
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"any_of none true -> skip",expect:0,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{any_of:[{tag:"macroengine_selftest_absent_xyz"},{tag:"macroengine_selftest_absent_abc"}]}}}
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"not false -> run",expect:1,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{not:{tag:"macroengine_selftest_absent_xyz"}}}}
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"not true -> skip",expect:0,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{not:{tag:"macroengine_selftest"}}}}

# --- 5b. nesting (regression: a nested group used to clobber the parent's depth) ---
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"all_of[any_of,tag] -> run",expect:1,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{all_of:[{any_of:[{tag:"macroengine_selftest_absent_xyz"},{tag:"macroengine_selftest"}]},{tag:"macroengine_selftest"}]}}}
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"all_of[any_of,absent] -> skip",expect:0,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{all_of:[{any_of:[{tag:"macroengine_selftest_absent_xyz"},{tag:"macroengine_selftest"}]},{tag:"macroengine_selftest_absent_xyz"}]}}}
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"any_of[all_of false,tag] -> run",expect:1,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{any_of:[{all_of:[{tag:"macroengine_selftest"},{tag:"macroengine_selftest_absent_xyz"}]},{tag:"macroengine_selftest"}]}}}
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"not[any_of none] -> run",expect:1,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{not:{any_of:[{tag:"macroengine_selftest_absent_xyz"},{tag:"macroengine_selftest_absent_abc"}]}}}}

# --- 6. nested group gating ----------------------------------------
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"group gated off -> skip",expect:0,entry:{commands:[{cmd:"data modify storage macroengine:engine _selftest_ran set value 1"}],condition:{tag:"macroengine_selftest_absent_xyz"}}}
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"group gated on -> run",expect:1,entry:{commands:[{cmd:"data modify storage macroengine:engine _selftest_ran set value 1"}],condition:{tag:"macroengine_selftest"}}}

# --- 7. malformed condition must fail CLOSED ------------------------
function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case {name:"malformed score -> skip",expect:0,entry:{cmd:"data modify storage macroengine:engine _selftest_ran set value 1",condition:{score:{min:5}}}}

# --- teardown + report ---------------------------------------------
tag @s remove macroengine_selftest
scoreboard players reset @s macroengine.tmp
data remove storage macroengine:engine _selftest_val
data remove storage macroengine:engine _selftest_ran

data modify storage macroengine:output selftest set value {}
execute store result storage macroengine:output selftest.pass int 1 run scoreboard players get $selftest_pass macroengine.tmp
execute store result storage macroengine:output selftest.fail int 1 run scoreboard players get $selftest_fail macroengine.tmp

tellraw @s [{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"pass ","color":"gray"},{"score":{"name":"$selftest_pass","objective":"macroengine.tmp"},"color":"green"},{"text":"  fail ","color":"gray"},{"score":{"name":"$selftest_fail","objective":"macroengine.tmp"},"color":"red"}]
execute if score $selftest_fail macroengine.tmp matches 1.. run tellraw @s [{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"the condition gate is NOT working — see FAIL lines above","color":"red","bold":true}]
execute if score $selftest_fail macroengine.tmp matches 0 run tellraw @s [{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"condition gate verified","color":"green"}]

scoreboard players reset $selftest_pass macroengine.tmp
scoreboard players reset $selftest_fail macroengine.tmp
scoreboard players reset $selftest_expected macroengine.tmp
scoreboard players reset $selftest_actual macroengine.tmp
