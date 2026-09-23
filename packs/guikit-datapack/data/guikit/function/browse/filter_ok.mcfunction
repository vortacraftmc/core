# #pass = 1 if guikit:work menu belongs in this player's filter. 0 and unset mean all.
scoreboard players set #pass guikit.tmp 1
execute unless score @s guikit.bfilt matches 1..7 run return 0
scoreboard players set #pass guikit.tmp 0
execute if score @s guikit.bfilt matches 1 if data storage guikit:work menu{container:"chest_minecart"} run scoreboard players set #pass guikit.tmp 1
execute if score @s guikit.bfilt matches 1 unless data storage guikit:work menu.container run scoreboard players set #pass guikit.tmp 1
execute if score @s guikit.bfilt matches 2 if data storage guikit:work menu{container:"hopper_minecart"} run scoreboard players set #pass guikit.tmp 1
execute if score @s guikit.bfilt matches 3 if data storage guikit:work menu{container:"barrel"} run scoreboard players set #pass guikit.tmp 1
execute if score @s guikit.bfilt matches 4 if data storage guikit:work menu{container:"ender_chest"} run scoreboard players set #pass guikit.tmp 1
execute if score @s guikit.bfilt matches 5 if data storage guikit:work menu{container:"trapped_chest"} run scoreboard players set #pass guikit.tmp 1
execute if score @s guikit.bfilt matches 6 if data storage guikit:work menu{container:"shulker_box"} run scoreboard players set #pass guikit.tmp 1
execute if score @s guikit.bfilt matches 7 if data storage guikit:work menu{container:"copper_chest"} run scoreboard players set #pass guikit.tmp 1
