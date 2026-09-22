function guikit:editor/load_state
execute store result score #page guikit.tmp run data get storage guikit:ed cur.page
execute if score #page guikit.tmp matches 8.. run tellraw @s {"text":"[guikit] Page limit is 9.","color":"red"}
execute if score #page guikit.tmp matches 8.. run return run function guikit:editor/schedule_resume
scoreboard players add #page guikit.tmp 1
execute store result storage guikit:ed cur.page int 1 run scoreboard players get #page guikit.tmp
function guikit:editor/edit/ensure_page
data modify storage guikit:ed cur.screen set value "edit"
function guikit:editor/save_state
function guikit:editor/schedule_resume
