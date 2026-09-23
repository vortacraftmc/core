# guikit :: play/last_trigger    as player  —  /trigger guikit.last
# Reopens the most recent menu this player opened. Permission 0, like guikit.open.
scoreboard players set @s guikit.last 0
scoreboard players enable @s guikit.last
function guikit:runtime/ensure_pid
execute store result storage guikit:ctx pid int 1 run scoreboard players get @s guikit.pid
data remove storage guikit:ctx last
function guikit:play/last_load with storage guikit:ctx
execute unless data storage guikit:ctx last run tellraw @s {"text":"[guikit] You have not opened a menu yet.","color":"red"}
execute unless data storage guikit:ctx last run return 0
function guikit:play/last_check with storage guikit:ctx
