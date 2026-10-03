# guikit :: internal/guard/sync     as cart, at cart
# A minecraft:interaction covers the cart while any other player is within 8 blocks.
# It is not a passenger: a passenger sits above the cart, and interaction height only
# grows upward, so riding would not cover the click. Same position + a larger box does.
# Hidden by killing it (not by teleporting below the world, which deletes the entity).
scoreboard players operation #guid guikit.tmp = @s guikit.uid
execute unless score #guid guikit.tmp matches 1.. run return 0
scoreboard players set #others guikit.tmp 0
execute as @a[distance=..8,gamemode=!spectator] unless score @s guikit.uid = #guid guikit.tmp run scoreboard players add #others guikit.tmp 1
execute if score #others guikit.tmp matches 1.. run function guikit:internal/guard/show
execute if score #others guikit.tmp matches 0 run function guikit:internal/guard/hide
