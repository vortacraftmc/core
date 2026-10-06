# Second click on the same page+slot within 2 seconds (40 ticks) runs the action.
execute unless data storage guikit:work w{confirm:1b} run return 0
execute store result score #page guikit.tmp run data get storage guikit:work page
execute store result score #slot guikit.tmp run data get storage guikit:work w.slot
scoreboard players set #key guikit.tmp 0
scoreboard players set #hundred guikit.tmp 100
scoreboard players operation #key guikit.tmp = #page guikit.tmp
scoreboard players operation #key guikit.tmp *= #hundred guikit.tmp
scoreboard players operation #key guikit.tmp += #slot guikit.tmp
execute if score @s guikit.arm = #key guikit.tmp if score @s guikit.armt matches 1.. run return run function guikit:play/act/confirm_ok
scoreboard players operation @s guikit.arm = #key guikit.tmp
scoreboard players set @s guikit.armt 40
scoreboard players set #blocked guikit.tmp 1
tellraw @s [{"text":"[GUI] ","color":"gray"},{"text":"Click again to confirm.","color":"gold"}]
