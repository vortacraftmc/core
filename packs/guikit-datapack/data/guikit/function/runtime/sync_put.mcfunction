# macro: $(id) $(n)
$data modify storage guikit:reg containers.gkc_$(n) set from storage guikit:work cdef
$data modify storage guikit:reg menus."guikit:m/$(id)" set value {alias:"gkm_$(n)",container:"gkc_$(n)"}
$execute as @a run tag @s remove guikit.m.gkm_$(n)
