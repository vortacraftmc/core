# macro: $(id)
$execute store result score #hit guikit.tmp run clear @s *[custom_data~{guikit:{w:1b,id:"hm$(id)"}}] 0
execute unless score #hit guikit.tmp matches 1.. run return 0
function guikit:editor/load_state
function guikit:editor/ui/begin_widget
data modify storage guikit:ed widget.kind set value "open"
data modify storage guikit:ed widget.item set value "minecraft:ender_eye"
data modify storage guikit:ed widget.name set value {text:"Open menu",color:"aqua",italic:false}
data modify storage guikit:ed widget.lore set value [{text:"Opens another menu",color:"gray",italic:false}]
data modify storage guikit:ed widget.to set from storage guikit:work id
function guikit:editor/edit/upsert
data modify storage guikit:ed cur.screen set value "edit"
function guikit:editor/save_state
function guikit:api/close
function guikit:editor/schedule_resume
