function guikit:editor/load_state
function guikit:editor/ui/set_pub_off with storage guikit:ed cur
data modify storage guikit:work id set from storage guikit:ed cur.menu
function guikit:runtime/sync_one with storage guikit:work
function guikit:editor/save_state
tellraw @s {"text":"[guikit] Hidden from the player list.","color":"gray"}
function guikit:editor/schedule_resume
