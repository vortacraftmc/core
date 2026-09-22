# guikit :: editor/home/fill     as player
function guikit:editor/load_state
function guikit:widget/pad
data modify storage guikit:work list set from storage guikit:lib order
execute store result score #skip guikit.tmp run data get storage guikit:ed cur.list_page
scoreboard players set #18 guikit.tmp 18
scoreboard players operation #skip guikit.tmp *= #18 guikit.tmp
scoreboard players set #drawn guikit.tmp 0
scoreboard players set #slot guikit.tmp 0
function guikit:editor/home/skip
function guikit:editor/home/draw_loop
function guikit:editor/home/toolbar
