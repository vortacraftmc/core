# macro: $(src) $(name) $(lore)     src is typed or held; name/lore are stored as strings, never executed
function guikit:editor/load_state
scoreboard players set #b guikit.tmp -1
execute store result score #b guikit.tmp run data get storage guikit:ed cur.slot
execute unless score #b guikit.tmp matches 0..26 run return run function guikit:editor/schedule_resume
function guikit:editor/ui/load_widget
execute if score #ok guikit.tmp matches 0 run tellraw @s {"text":"[guikit] Place an action in this slot first.","color":"red"}
execute if score #ok guikit.tmp matches 0 run return run function guikit:editor/schedule_resume
$data modify storage guikit:ed src set value "$(src)"
$data modify storage guikit:ed name_in set value "$(name)"
$data modify storage guikit:ed lore_in set value "$(lore)"
scoreboard players set #named guikit.tmp 0
execute if data storage guikit:ed {src:"held"} run function guikit:editor/ui/rename_held
execute if data storage guikit:ed {src:"typed"} run function guikit:editor/ui/rename_typed
execute if score #named guikit.tmp matches 0 run data remove storage guikit:ed src
execute if score #named guikit.tmp matches 0 run data remove storage guikit:ed name_in
execute if score #named guikit.tmp matches 0 run data remove storage guikit:ed lore_in
execute if score #named guikit.tmp matches 0 run return run function guikit:editor/schedule_resume
function guikit:editor/ui/rename_lore
data remove storage guikit:ed src
data remove storage guikit:ed name_in
data remove storage guikit:ed lore_in
function guikit:editor/edit/upsert
function guikit:editor/save_state
tellraw @s {"text":"[guikit] Renamed the icon.","color":"green"}
function guikit:editor/schedule_resume
