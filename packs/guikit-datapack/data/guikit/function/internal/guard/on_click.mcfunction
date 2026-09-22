# as interaction. Backup for a click the advancement did not clear.
scoreboard players operation #guid guikit.tmp = @s guikit.uid
scoreboard players set #gdone guikit.tmp 0
execute if data entity @s interaction on target run function guikit:internal/guard/from_player
execute if score #gdone guikit.tmp matches 0 if data entity @s attack on attacker run function guikit:internal/guard/from_player
data remove entity @s interaction
data remove entity @s attack
