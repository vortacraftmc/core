# guikit :: runtime/on_open     as player, uid already assigned, before the first redraw
execute unless data storage guikit:ed pending.mode run return 0
execute store result storage guikit:ctx uid int 1 run scoreboard players get @s guikit.uid
data modify storage guikit:ctx mode set from storage guikit:ed pending.mode
data modify storage guikit:ctx menu set from storage guikit:ed pending.menu
data modify storage guikit:ctx alias set from storage guikit:ed pending.alias
function guikit:runtime/bind with storage guikit:ctx
