# macro: $(menu_id) $(page)
data remove storage guikit:work menu
$data modify storage guikit:work menu set from storage guikit:lib menus.$(menu_id)
execute unless data storage guikit:work menu run return 0
execute store result storage guikit:work n int 1 run data get storage guikit:work menu.n
data remove storage guikit:work src
$data modify storage guikit:work src set from storage guikit:work menu.pages[$(page)].widgets
execute unless data storage guikit:work src run return 0
scoreboard players set #hit guikit.tmp 0
function guikit:play/probe_loop
