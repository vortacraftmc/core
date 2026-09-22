function guikit:editor/load_state
function guikit:editor/ui/capture_hand
execute if score #ok guikit.tmp matches 0 run return run function guikit:editor/schedule_resume
function guikit:editor/ui/begin_widget
data modify storage guikit:ed widget.kind set value "decor"
data modify storage guikit:ed widget.item set from storage guikit:ed hand
data modify storage guikit:ed widget.name set value {text:"Decoration",italic:false}
data modify storage guikit:ed widget.lore set value [{text:"Not clickable",color:"gray",italic:false}]
function guikit:editor/edit/upsert
function guikit:editor/save_state
function guikit:editor/schedule_resume
