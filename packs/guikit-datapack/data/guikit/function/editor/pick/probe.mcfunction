scoreboard players set #hit guikit.tmp 0
execute store result score #hit guikit.tmp run clear @s *[custom_data~{guikit:{w:1b,id:"pcancel"}}] 0
execute if score #hit guikit.tmp matches 1.. run return run function guikit:editor/ui/back
execute store result score #hit guikit.tmp run clear @s *[custom_data~{guikit:{w:1b,id:"hclose"}}] 0
execute if score #hit guikit.tmp matches 1.. run return run function guikit:api/close
execute store result score #hit guikit.tmp run clear @s *[custom_data~{guikit:{w:1b,id:"hprev"}}] 0
execute if score #hit guikit.tmp matches 1.. run return run function guikit:editor/home/page_prev
execute store result score #hit guikit.tmp run clear @s *[custom_data~{guikit:{w:1b,id:"hnext"}}] 0
execute if score #hit guikit.tmp matches 1.. run return run function guikit:editor/home/page_next
function guikit:editor/load_state
data modify storage guikit:work list set from storage guikit:lib order
function guikit:editor/pick/probe_loop
