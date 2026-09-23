scoreboard players set #hit guikit.tmp 0
execute store result score #hit guikit.tmp run clear @s *[custom_data~{guikit:{w:1b,id:"bclose"}}] 0
execute if score #hit guikit.tmp matches 1.. run return run function guikit:api/close
execute store result score #hit guikit.tmp run clear @s *[custom_data~{guikit:{w:1b,id:"bprev"}}] 0
execute if score #hit guikit.tmp matches 1.. run return run function guikit:browse/page_prev
execute store result score #hit guikit.tmp run clear @s *[custom_data~{guikit:{w:1b,id:"bnext"}}] 0
execute if score #hit guikit.tmp matches 1.. run return run function guikit:browse/page_next
execute store result score #hit guikit.tmp run clear @s *[custom_data~{guikit:{w:1b,id:"bhelp"}}] 0
execute if score #hit guikit.tmp matches 1.. run return run function guikit:browse/help_click
execute store result score #hit guikit.tmp run clear @s *[custom_data~{guikit:{w:1b,id:"bsort"}}] 0
execute if score #hit guikit.tmp matches 1.. run return run function guikit:browse/click_sort
execute store result score #hit guikit.tmp run clear @s *[custom_data~{guikit:{w:1b,id:"bfilt"}}] 0
execute if score #hit guikit.tmp matches 1.. run return run function guikit:browse/click_filter
data modify storage guikit:work list set from storage guikit:lib order
function guikit:browse/probe_loop
