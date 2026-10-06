function guikit:editor/load_state
function guikit:editor/ui/delete_do with storage guikit:ed cur
data modify storage guikit:work list set from storage guikit:lib order
data modify storage guikit:work out set value []
data modify storage guikit:work drop set from storage guikit:ed cur.menu
function guikit:editor/ui/delete_order
data modify storage guikit:lib order set from storage guikit:work out
data modify storage guikit:ed cur.screen set value "home"
data modify storage guikit:ed cur.menu set value "-"
data modify storage guikit:ed cur.page set value 0
function guikit:editor/save_state
tellraw @s {"text":"[guikit] Menu deleted.","color":"red"}
function guikit:editor/schedule_resume
