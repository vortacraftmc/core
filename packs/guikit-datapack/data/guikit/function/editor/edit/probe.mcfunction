scoreboard players set #hit guikit.tmp 0
execute store result score #hit guikit.tmp run clear @s *[custom_data~{guikit:{w:1b,id:"edtools"}}] 0
execute if score #hit guikit.tmp matches 1.. run return run function guikit:editor/edit/on_tools
execute store result score #hit guikit.tmp run clear @s *[custom_data~{guikit:{w:1b,id:"edlock"}}] 0
execute if score #hit guikit.tmp matches 1.. run return run tellraw @s {"text":"[guikit] That slot does not exist on this container.","color":"red"}
scoreboard players set #i guikit.tmp 0
function guikit:editor/edit/probe_slots
