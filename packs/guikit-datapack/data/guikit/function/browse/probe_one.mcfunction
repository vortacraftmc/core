# macro: $(id)
$execute store result score #hit guikit.tmp run clear @s *[custom_data~{guikit:{w:1b,id:"hm$(id)"}}] 0
execute unless score #hit guikit.tmp matches 1.. run return 0
data modify storage guikit:work menu set from storage guikit:work id
function guikit:play/open_id with storage guikit:work
