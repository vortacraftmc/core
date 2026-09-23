execute unless score @s guikit.bpage matches 1.. run tellraw @s {"text":"[guikit] Already on the first page.","color":"gray"}
execute unless score @s guikit.bpage matches 1.. run return 0
scoreboard players remove @s guikit.bpage 1
scoreboard players set @s guikit.dirty 1
