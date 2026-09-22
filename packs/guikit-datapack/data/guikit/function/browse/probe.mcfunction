scoreboard players set #hit guikit.tmp 0
execute store result score #hit guikit.tmp run clear @s *[custom_data~{guikit:{w:1b,id:"bclose"}}] 0
execute if score #hit guikit.tmp matches 1.. run return run function guikit:api/close
data modify storage guikit:work list set from storage guikit:lib order
function guikit:browse/probe_loop
