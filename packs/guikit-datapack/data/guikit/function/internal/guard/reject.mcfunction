# Non-owner clicked the guard or the cart. Do not reset their menu timer.
function guikit:internal/safe_clear
execute if score @s guikit.gmsg matches 1.. run return 0
scoreboard players set @s guikit.gmsg 20
tellraw @s [{"text":"[guikit] ","color":"gray"},{"text":"That menu belongs to another player.","color":"red"}]
execute unless score @s guikit.uid matches 1.. run dialog show @s guikit:foreign
