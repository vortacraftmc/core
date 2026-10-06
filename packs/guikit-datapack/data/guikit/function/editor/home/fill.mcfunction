# guikit :: editor/home/fill     as player
function guikit:editor/load_state
scoreboard players set @s guikit.rfiv 20
function guikit:widget/pad
data modify storage guikit:work list set from storage guikit:lib order
execute store result score #skip guikit.tmp run data get storage guikit:ed cur.list_page
scoreboard players set #18 guikit.tmp 18
scoreboard players operation #skip guikit.tmp *= #18 guikit.tmp
scoreboard players set #drawn guikit.tmp 0
scoreboard players set #slot guikit.tmp 0
function guikit:editor/home/skip
function guikit:editor/home/draw_loop
scoreboard players set #lp guikit.tmp 0
execute if score #drawn guikit.tmp matches 0 store result score #lp guikit.tmp run data get storage guikit:ed cur.list_page
execute if score #drawn guikit.tmp matches 0 if score #lp guikit.tmp matches 1.. run return run function guikit:editor/home/step_back
function guikit:editor/home/toolbar
