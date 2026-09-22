# macro: $(cost)     only the tokens the give dialog offers
$data modify storage guikit:ed cost set value "$(cost)"
execute if data storage guikit:ed {cost:"none"} run data remove storage guikit:ed cost
execute if data storage guikit:ed {cost:"none"} run return 0
execute if data storage guikit:ed {cost:"diamond1"} run data modify storage guikit:ed widget.cost_item set value "minecraft:diamond"
execute if data storage guikit:ed {cost:"diamond1"} run data modify storage guikit:ed widget.cost_count set value 1
execute if data storage guikit:ed {cost:"diamond3"} run data modify storage guikit:ed widget.cost_item set value "minecraft:diamond"
execute if data storage guikit:ed {cost:"diamond3"} run data modify storage guikit:ed widget.cost_count set value 3
execute if data storage guikit:ed {cost:"emerald1"} run data modify storage guikit:ed widget.cost_item set value "minecraft:emerald"
execute if data storage guikit:ed {cost:"emerald1"} run data modify storage guikit:ed widget.cost_count set value 1
execute if data storage guikit:ed {cost:"gold8"} run data modify storage guikit:ed widget.cost_item set value "minecraft:gold_ingot"
execute if data storage guikit:ed {cost:"gold8"} run data modify storage guikit:ed widget.cost_count set value 8
execute if data storage guikit:ed {cost:"iron16"} run data modify storage guikit:ed widget.cost_item set value "minecraft:iron_ingot"
execute if data storage guikit:ed {cost:"iron16"} run data modify storage guikit:ed widget.cost_count set value 16
data remove storage guikit:ed cost
