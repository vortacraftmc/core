# 1 cycles. 2 all, 3 chest, 4 hopper, 5 barrel, 6 ender, 7 trapped, 8 shulker, 9 copper.
scoreboard players operation #want guikit.tmp = @s guikit.filter
scoreboard players set @s guikit.filter 0
scoreboard players enable @s guikit.filter
function guikit:browse/apply_filter
execute unless score #ok guikit.tmp matches 1 run return run function guikit:browse/usage_filter
scoreboard players set @s guikit.bpage 0
scoreboard players set #keep guikit.tmp 1
function guikit:browse/show
function guikit:browse/tell_filter
