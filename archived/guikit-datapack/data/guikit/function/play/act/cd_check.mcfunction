# macro: $(pid) $(n) $(page) $(slot)
# #left is ticks still remaining, or 0. End time is an absolute #tick value.
scoreboard players set #left guikit.tmp 0
scoreboard players set #has guikit.tmp 0
$execute if score p$(pid)_c$(n)_$(page)_$(slot) guikit.var matches 1.. run scoreboard players set #has guikit.tmp 1
execute if score #has guikit.tmp matches 0 run return 0
$scoreboard players operation #left guikit.tmp = p$(pid)_c$(n)_$(page)_$(slot) guikit.var
scoreboard players operation #left guikit.tmp -= #tick guikit.const
execute if score #left guikit.tmp matches ..0 run scoreboard players set #left guikit.tmp 0
