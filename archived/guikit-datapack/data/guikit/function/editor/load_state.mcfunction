function guikit:runtime/ensure_pid
execute store result storage guikit:ctx pid int 1 run scoreboard players get @s guikit.pid
function guikit:editor/load_state_do with storage guikit:ctx
execute unless data storage guikit:ed cur.screen run data modify storage guikit:ed cur.screen set value "home"
execute unless data storage guikit:ed cur.page run data modify storage guikit:ed cur.page set value 0
execute unless data storage guikit:ed cur.list_page run data modify storage guikit:ed cur.list_page set value 0
execute unless data storage guikit:ed cur.menu run data modify storage guikit:ed cur.menu set value "-"
execute unless data storage guikit:ed cur.slot run data modify storage guikit:ed cur.slot set value -1
