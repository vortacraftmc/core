# Start the per-player cooldown after a click that was allowed to run.
execute unless data storage guikit:work w.cd run return 0
execute unless score #acted guikit.tmp matches 1.. run return 0
function guikit:runtime/ensure_pid
execute store result score #add guikit.tmp run data get storage guikit:work w.cd
scoreboard players operation #end guikit.tmp = #tick guikit.const
scoreboard players operation #end guikit.tmp += #add guikit.tmp
execute store result storage guikit:work pid int 1 run scoreboard players get @s guikit.pid
execute store result storage guikit:work end int 1 run scoreboard players get #end guikit.tmp
execute store result storage guikit:work slot int 1 run data get storage guikit:work w.slot
function guikit:play/act/cd_arm_do with storage guikit:work
