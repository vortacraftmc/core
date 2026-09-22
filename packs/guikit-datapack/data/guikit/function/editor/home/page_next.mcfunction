function guikit:editor/load_state
execute store result score #page guikit.tmp run data get storage guikit:ed cur.list_page
scoreboard players add #page guikit.tmp 1
execute store result storage guikit:ed cur.list_page int 1 run scoreboard players get #page guikit.tmp
function guikit:editor/save_state
scoreboard players set @s guikit.dirty 1
