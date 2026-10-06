# as the clicking player. #guid is the guard's uid (the cart owner).
scoreboard players set #gdone guikit.tmp 1
scoreboard players set #own guikit.tmp 0
execute if score @s guikit.uid = #guid guikit.tmp run scoreboard players set #own guikit.tmp 1
execute if score #own guikit.tmp matches 1.. run function guikit:internal/guard/owner_blocked
execute if score #own guikit.tmp matches 0 run function guikit:internal/guard/reject
