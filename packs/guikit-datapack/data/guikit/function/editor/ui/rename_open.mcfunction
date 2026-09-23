function guikit:editor/load_state
scoreboard players set #b guikit.tmp -1
execute store result score #b guikit.tmp run data get storage guikit:ed cur.slot
execute unless score #b guikit.tmp matches 0..26 run return run tellraw @s {"text":"[guikit] Pick a slot first.","color":"red"}
function guikit:editor/ui/load_widget
execute if score #ok guikit.tmp matches 0 run tellraw @s {"text":"[guikit] Place an action in this slot first.","color":"red"}
execute if score #ok guikit.tmp matches 0 run return run dialog show @s guikit:slot
tellraw @s [{"text":"[guikit] Current name: ","color":"gray"},{"nbt":"widget.name","storage":"guikit:ed","interpret":false,"color":"white"}]
tag @s add guikit.rdialog
schedule function guikit:editor/ui/rename_show 2t
