# macro: $(id)     id is always m<number>, never player text
$data modify storage guikit:work menu set from storage guikit:lib menus.$(id)
execute unless data storage guikit:work menu run return 0
execute store result score #n guikit.tmp run data get storage guikit:work menu.n
execute store result storage guikit:work n int 1 run scoreboard players get #n guikit.tmp
$data modify storage guikit:work id set value "$(id)"
function guikit:runtime/sync_container
function guikit:runtime/sync_put with storage guikit:work
