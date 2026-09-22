# guikit :: runtime/clear_tags     #guikit:clear_tags — uid already copied to #uid and reset on the player
tag @s remove guikit.m.editor
tag @s remove guikit.m.browse
execute store result storage guikit:ctx uid int 1 run scoreboard players get #uid guikit.tmp
execute if score #uid guikit.tmp matches 1.. run function guikit:runtime/clear_alias with storage guikit:ctx
