# macro: $(msg) $(lore)
function guikit:editor/load_state
function guikit:editor/ui/begin_widget
data modify storage guikit:ed widget.kind set value "tell"
data modify storage guikit:ed widget.item set value "minecraft:book"
data modify storage guikit:ed widget.name set value {text:"Message",color:"gold",italic:false}
data modify storage guikit:ed widget.lore set value [{text:"Click to read",color:"gray",italic:false}]
function guikit:editor/ui/apply_hand
$function guikit:editor/ui/tell_store {msg:"$(msg)",lore:"$(lore)"}
function guikit:editor/edit/upsert
function guikit:editor/save_state
function guikit:editor/schedule_resume
