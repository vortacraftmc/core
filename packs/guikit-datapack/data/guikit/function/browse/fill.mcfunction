function guikit:widget/pad
scoreboard players set @s guikit.rfiv 20
scoreboard players set #vcount guikit.tmp 0
function guikit:browse/build_view
execute store result score #vcount guikit.tmp run data get storage guikit:work view
data modify storage guikit:work list set from storage guikit:work view
execute store result score #skip guikit.tmp run scoreboard players get @s guikit.bpage
scoreboard players set #18 guikit.tmp 18
scoreboard players operation #skip guikit.tmp *= #18 guikit.tmp
scoreboard players set #drawn guikit.tmp 0
scoreboard players set #slot guikit.tmp 0
function guikit:editor/home/skip
function guikit:browse/draw_loop
execute if score #drawn guikit.tmp matches 0 if score @s guikit.bpage matches 1.. run return run function guikit:browse/step_back
function guikit:browse/toolbar
execute if score #drawn guikit.tmp matches 0 run function guikit:browse/empty
