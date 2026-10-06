function guikit:editor/load_state
function guikit:editor/ui/capture_hand
execute if score #ok guikit.tmp matches 0 run return run function guikit:editor/schedule_resume
function guikit:editor/read_menu
function guikit:editor/ui/begin_widget
data modify storage guikit:ed widget.kind set value "add"
data modify storage guikit:ed widget.item set from storage guikit:ed hand
data modify storage guikit:ed widget.delta set value 1
data modify storage guikit:ed widget.min set value 0
data modify storage guikit:ed widget.max set value 99
data modify storage guikit:ed widget.name set value {text:"Counter",color:"aqua",italic:false}
data modify storage guikit:ed widget.lore set value [{text:"Click to add 1",color:"gray",italic:false}]
function guikit:editor/ui/make_key
function guikit:editor/edit/upsert
function guikit:editor/save_state
function guikit:editor/schedule_resume
