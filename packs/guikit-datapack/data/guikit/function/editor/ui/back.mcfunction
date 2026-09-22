function guikit:editor/load_state
execute if data storage guikit:ed cur{screen:"pick"} run data modify storage guikit:ed cur.screen set value "edit"
function guikit:editor/save_state
function guikit:editor/schedule_resume
