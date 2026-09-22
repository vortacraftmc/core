data modify storage guikit:work menu_id set from storage guikit:sess cur.menu
execute store result storage guikit:work page int 1 run scoreboard players get @s guikit.page
function guikit:play/probe_load with storage guikit:work
