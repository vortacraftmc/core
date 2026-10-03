# macro: $(n) $(page) $(slot)
$execute store result score #hit guikit.tmp run clear @s *[custom_data~{guikit:{w:1b,id:"p$(n)_$(page)_$(slot)"}}] 0
execute if score #hit guikit.tmp matches 1.. run function guikit:play/act
