# macro: $(snd)     one of the six tokens above
function guikit:editor/load_state
function guikit:editor/ui/begin_widget
data modify storage guikit:ed widget.kind set value "sound"
data modify storage guikit:ed widget.item set value "minecraft:note_block"
data modify storage guikit:ed widget.name set value {text:"Sound",italic:false}
data modify storage guikit:ed widget.lore set value [{text:"Only you hear it",color:"gray",italic:false}]
function guikit:editor/ui/apply_hand
$function guikit:editor/ui/sound_store {snd:"$(snd)"}
function guikit:editor/edit/upsert
function guikit:editor/save_state
function guikit:editor/schedule_resume
