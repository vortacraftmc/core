function guikit:editor/load_state
execute store result storage guikit:ed cur.slot int 1 run scoreboard players get #eslot guikit.tmp
data modify storage guikit:ed cur.dialog set value "slot"
function guikit:editor/save_state
function guikit:api/close
function guikit:editor/schedule_dialog
