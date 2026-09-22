# as cart. Remove this owner's guard so they can right-click the cart.
execute as @e[type=minecraft:interaction,tag=guikit.guard] if score @s guikit.uid = #guid guikit.tmp run kill @s
