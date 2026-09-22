execute if score #i guikit.tmp matches 36.. run return 0
execute store result storage guikit:ctx i int 1 run scoreboard players get #i guikit.tmp
function guikit:internal/guard/purge_slot with storage guikit:ctx
scoreboard players add #i guikit.tmp 1
function guikit:internal/guard/purge_loop
