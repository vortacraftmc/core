function guikit:editor/load_state
execute store result score #page guikit.tmp run data get storage guikit:ed cur.page
execute unless score #page guikit.tmp matches 1.. run tellraw @s {"text":"[guikit] Already on page 1.","color":"gray"}
execute unless score #page guikit.tmp matches 1.. run return run function guikit:editor/schedule_resume
scoreboard players remove #page guikit.tmp 1
execute store result storage guikit:ed cur.page int 1 run scoreboard players get #page guikit.tmp
data modify storage guikit:ed cur.screen set value "edit"
function guikit:editor/save_state
function guikit:editor/schedule_resume
