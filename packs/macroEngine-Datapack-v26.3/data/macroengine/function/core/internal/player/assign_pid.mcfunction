execute store result score $next_pid macroengine.tmp run data get storage macroengine:engine _pid_seq

scoreboard players add $next_pid macroengine.tmp 1

$execute store result storage macroengine:engine player_pids.$(player) int 1 run scoreboard players get $next_pid macroengine.tmp
$scoreboard players operation @a[name=$(player),limit=1] macroengine.pid = $next_pid macroengine.tmp

execute store result storage macroengine:engine _pid_seq int 1 run scoreboard players get $next_pid macroengine.tmp

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.player_internal_assign_pid","color":"aqua"},{"text":"$(player)","color":"white"},{"translate":"macroengine.fmt.arrow_pid","color":"#555555"},{"score":{"name":"$next_pid","objective":"macroengine.tmp"},"color":"green"}]
