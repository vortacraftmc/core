execute store result score #lp guikit.tmp run data get storage guikit:ed cur.list_page
execute unless score #lp guikit.tmp matches 1.. run return 0
scoreboard players remove #lp guikit.tmp 1
execute store result storage guikit:ed cur.list_page int 1 run scoreboard players get #lp guikit.tmp
function guikit:editor/save_state
function guikit:editor/home/fill
