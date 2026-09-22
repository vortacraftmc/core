# as cart, at cart. #guid is this cart's uid.
# width 2.4 covers a chest boat (1.375) and a minecart (0.98), with margin so the ray hits this box first.
# height 1.8 covers both. Size is fixed at summon; an existing guard is only moved.
execute as @e[type=minecraft:interaction,tag=guikit.guard] if score @s guikit.uid = #guid guikit.tmp run tag @s add guikit.gthis
execute unless entity @e[type=minecraft:interaction,tag=guikit.gthis,limit=1] run summon minecraft:interaction ~ ~ ~ {width:2.4f,height:1.8f,response:0b,Tags:["guikit.guard","guikit.gthis"]}
scoreboard players operation @e[type=minecraft:interaction,tag=guikit.gthis,limit=1] guikit.uid = #guid guikit.tmp
tp @e[type=minecraft:interaction,tag=guikit.gthis,limit=1] ~ ~ ~
tag @e[type=minecraft:interaction,tag=guikit.gthis] remove guikit.gthis
