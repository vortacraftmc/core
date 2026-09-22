function guikit:editor/load_state
execute store result score #page guikit.tmp run data get storage guikit:ed cur.list_page
execute unless score #page guikit.tmp matches 1.. run tellraw @s {"text":"[guikit] Already on the first page.","color":"gray"}
execute unless score #page guikit.tmp matches 1.. run return 0
scoreboard players remove #page guikit.tmp 1
execute store result storage guikit:ed cur.list_page int 1 run scoreboard players get #page guikit.tmp
function guikit:editor/save_state
scoreboard players set @s guikit.dirty 1
