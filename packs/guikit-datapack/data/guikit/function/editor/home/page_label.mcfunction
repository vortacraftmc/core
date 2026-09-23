scoreboard players set #show guikit.tmp 1
execute store result score #lp guikit.tmp run data get storage guikit:ed cur.list_page
scoreboard players operation #show guikit.tmp += #lp guikit.tmp
execute store result storage guikit:ctx page int 1 run scoreboard players get #show guikit.tmp
function guikit:editor/home/page_label_do with storage guikit:ctx
