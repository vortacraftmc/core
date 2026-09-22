# macro: $(url)
function guikit:editor/load_state
function guikit:editor/ui/begin_widget
data modify storage guikit:ed widget.kind set value "link"
data modify storage guikit:ed widget.item set value "minecraft:paper"
data modify storage guikit:ed widget.name set value {text:"Link",color:"aqua",italic:false}
data modify storage guikit:ed widget.lore set value [{text:"Click to open",color:"gray",italic:false}]
function guikit:editor/ui/apply_hand
$function guikit:editor/ui/link_store {url:"$(url)"}
function guikit:editor/edit/upsert
function guikit:editor/save_state
function guikit:editor/schedule_resume
