# macro: $(container)     dialog option id, mapped to a fixed container name
$data modify storage guikit:ed ctype set value "$(container)"
execute if data storage guikit:ed {ctype:"chest"} run function guikit:editor/ui/set_container_chest with storage guikit:ed cur
execute if data storage guikit:ed {ctype:"hopper"} run function guikit:editor/ui/set_container_hopper with storage guikit:ed cur
execute if data storage guikit:ed {ctype:"barrel"} run function guikit:editor/ui/set_container_barrel with storage guikit:ed cur
execute if data storage guikit:ed {ctype:"ender"} run function guikit:editor/ui/set_container_ender with storage guikit:ed cur
execute if data storage guikit:ed {ctype:"trapped"} run function guikit:editor/ui/set_container_trapped with storage guikit:ed cur
execute if data storage guikit:ed {ctype:"shulker"} run function guikit:editor/ui/set_container_shulker with storage guikit:ed cur
execute if data storage guikit:ed {ctype:"copper"} run function guikit:editor/ui/set_container_copper with storage guikit:ed cur
data remove storage guikit:ed ctype
