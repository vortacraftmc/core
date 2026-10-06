# macro: $(page)
function guikit:editor/load_state
function guikit:editor/ui/begin_widget
data modify storage guikit:ed widget.kind set value "page"
data modify storage guikit:ed widget.item set value "minecraft:arrow"
data modify storage guikit:ed widget.name set value {text:"Go to page",italic:false}
data modify storage guikit:ed widget.lore set value []
function guikit:editor/ui/apply_hand
$execute store result storage guikit:ed widget.to int 1 run scoreboard players set #to guikit.tmp $(page)
function guikit:editor/edit/upsert
function guikit:editor/save_state
function guikit:editor/schedule_resume
