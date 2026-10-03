# vc-gate: sink guard, disabled unless macroengine:gate/v26_4 state is active
execute unless data storage macroengine:gate/v26_4 {state:"active"} run return fail
scoreboard players set $pr_pid macroengine.tmp 0
$execute store result score $pr_pid macroengine.tmp run data get storage macroengine:engine player_pids.$(player)
execute if score $pr_pid macroengine.tmp matches 0 run return 0

data modify storage macroengine:engine _pr_tmp set value {result:0b}
execute as @a if score @s macroengine.pid = $pr_pid macroengine.tmp run execute if entity @s[tag=macroengine.admin] run data modify storage macroengine:engine _pr_tmp.result set value 1b
$execute as @a if score @s macroengine.pid = $pr_pid macroengine.tmp run execute if entity @s[tag=perm.$(perm)] run data modify storage macroengine:engine _pr_tmp.result set value 1b

$execute if data storage macroengine:engine _pr_tmp{result:0b} run execute as @a if score @s macroengine.pid = $pr_pid macroengine.tmp run tellraw @s ["",{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"✘ ","color":"red"},{"text":"$(perm)","color":"yellow"},{"text":" — you don't have this permission.","color":"red"}]
execute if data storage macroengine:engine _pr_tmp{result:0b} run return 0

$execute as @a if score @s macroengine.pid = $pr_pid macroengine.tmp at @s run $(cmd)

data remove storage macroengine:engine _pr_tmp