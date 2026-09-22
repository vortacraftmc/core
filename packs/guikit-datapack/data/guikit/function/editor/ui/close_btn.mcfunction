function guikit:editor/load_state
function guikit:editor/ui/begin_widget
data modify storage guikit:ed widget.kind set value "close"
data modify storage guikit:ed widget.item set value "minecraft:barrier"
data modify storage guikit:ed widget.name set value {text:"Close",color:"red",italic:false}
data modify storage guikit:ed widget.lore set value []
function guikit:editor/ui/apply_hand
function guikit:editor/edit/upsert
function guikit:editor/save_state
function guikit:editor/schedule_resume
