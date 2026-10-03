scoreboard players set #ok guikit.tmp 0
execute if score #want guikit.tmp matches 1 run function guikit:browse/sort_cycle
execute if score #want guikit.tmp matches 1 run scoreboard players set #ok guikit.tmp 1
execute if score #want guikit.tmp matches 2 run scoreboard players set @s guikit.bsort 0
execute if score #want guikit.tmp matches 2 run scoreboard players set #ok guikit.tmp 1
execute if score #want guikit.tmp matches 3 run scoreboard players set @s guikit.bsort 1
execute if score #want guikit.tmp matches 3 run scoreboard players set #ok guikit.tmp 1
