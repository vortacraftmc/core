scoreboard players set #blocked guikit.tmp 1
scoreboard players operation #secs guikit.tmp = #left guikit.tmp
scoreboard players add #secs guikit.tmp 19
scoreboard players set #twenty guikit.tmp 20
scoreboard players operation #secs guikit.tmp /= #twenty guikit.tmp
execute if score #secs guikit.tmp matches ..0 run scoreboard players set #secs guikit.tmp 1
tellraw @s [{"text":"[GUI] ","color":"gray"},{"text":"Wait ","color":"red"},{"score":{"name":"#secs","objective":"guikit.tmp"},"color":"red"},{"text":"s.","color":"red"}]
