scoreboard players set #ok guikit.tmp 0
execute unless data entity @s SelectedItem.id run tellraw @s {"text":"[guikit] Hold the item you want to use, then try again.","color":"red"}
execute unless data entity @s SelectedItem.id run return 0
data modify storage guikit:ed hand set from entity @s SelectedItem.id
scoreboard players set #ok guikit.tmp 1
