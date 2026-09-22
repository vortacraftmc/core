# as interaction that this player just clicked
scoreboard players operation #guid guikit.tmp = @s guikit.uid
data remove entity @s interaction
data remove entity @s attack
execute as @a[tag=guikit.gclick,limit=1] run function guikit:internal/guard/from_player
