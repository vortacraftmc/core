scoreboard players set #show guikit.tmp 1
scoreboard players operation #show guikit.tmp += @s guikit.bpage
execute store result storage guikit:ctx page int 1 run scoreboard players get #show guikit.tmp
execute store result storage guikit:ctx count int 1 run scoreboard players get #vcount guikit.tmp
function guikit:browse/page_label_do with storage guikit:ctx
