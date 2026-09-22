# macro: $(count) $(cost)     count/cost come from a dialog we authored
function guikit:editor/load_state
function guikit:editor/ui/capture_hand
execute if score #ok guikit.tmp matches 0 run return run function guikit:editor/schedule_resume
function guikit:editor/ui/begin_widget
data modify storage guikit:ed widget.kind set value "give"
data modify storage guikit:ed widget.item set from storage guikit:ed hand
data modify storage guikit:ed widget.give set from storage guikit:ed hand
data modify storage guikit:ed widget.name set value {text:"Take item",color:"yellow",italic:false}
data modify storage guikit:ed widget.lore set value [{text:"Click to receive",color:"gray",italic:false}]
$execute store result storage guikit:ed widget.count int 1 run scoreboard players set #count guikit.tmp $(count)
$function guikit:editor/ui/give_cost {cost:"$(cost)"}
function guikit:editor/edit/upsert
function guikit:editor/save_state
function guikit:editor/schedule_resume
