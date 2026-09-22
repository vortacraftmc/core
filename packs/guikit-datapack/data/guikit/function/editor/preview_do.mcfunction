tag @s remove guikit.preview
function guikit:editor/load_state
function guikit:play/open_id with storage guikit:ed cur
tellraw @s [{"text":"[guikit] Preview. ","color":"gray"},{"text":"Return to the editor","color":"aqua","click_event":{"action":"suggest_command","command":"/function guikit:editor/resume"}}]
