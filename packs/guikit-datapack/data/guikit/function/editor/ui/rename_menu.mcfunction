# macro: $(name)
function guikit:editor/load_state
$function guikit:editor/ui/settings_name {name:"$(name)"}
data modify storage guikit:work id set from storage guikit:ed cur.menu
function guikit:runtime/sync_one with storage guikit:work
function guikit:editor/save_state
tellraw @s {"text":"[guikit] Renamed.","color":"green"}
function guikit:editor/schedule_resume
