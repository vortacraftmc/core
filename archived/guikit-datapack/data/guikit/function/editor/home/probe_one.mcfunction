# macro: $(id)
$execute store result score #hit guikit.tmp run clear @s *[custom_data~{guikit:{w:1b,id:"hm$(id)"}}] 0
execute unless score #hit guikit.tmp matches 1.. run return 0
data modify storage guikit:ed cur.menu set from storage guikit:work id
data modify storage guikit:ed cur.page set value 0
data modify storage guikit:ed cur.screen set value "edit"
function guikit:editor/save_state
function guikit:api/close
function guikit:editor/schedule_resume
