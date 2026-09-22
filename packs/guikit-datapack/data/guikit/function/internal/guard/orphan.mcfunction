# as guard. Kill it if no cart still carries this uid.
scoreboard players set #guid guikit.tmp 0
scoreboard players operation #guid guikit.tmp = @s guikit.uid
execute unless score #guid guikit.tmp matches 1.. run return run kill @s
scoreboard players set #gfound guikit.tmp 0
execute as @e[type=#guikit:container,tag=guikit.cart] if score @s guikit.uid = #guid guikit.tmp run scoreboard players set #gfound guikit.tmp 1
execute if score #gfound guikit.tmp matches 0 run kill @s
