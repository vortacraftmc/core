# 1 cycles, 2 oldest, 3 newest. Bare /trigger guikit.sort is 1.
scoreboard players operation #want guikit.tmp = @s guikit.sort
scoreboard players set @s guikit.sort 0
scoreboard players enable @s guikit.sort
function guikit:browse/apply_sort
execute unless score #ok guikit.tmp matches 1 run return run function guikit:browse/usage_sort
scoreboard players set @s guikit.bpage 0
scoreboard players set #keep guikit.tmp 1
function guikit:browse/show
function guikit:browse/tell_sort
