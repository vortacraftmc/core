# guikit :: editor/edit/fill     as player
function guikit:editor/load_state
function guikit:editor/read_menu
function guikit:widget/pad
scoreboard players set #limit guikit.tmp 27
execute if data storage guikit:work menu{container:"hopper_minecart"} run scoreboard players set #limit guikit.tmp 5
execute store result storage guikit:work page int 1 run data get storage guikit:ed cur.page
function guikit:editor/edit/load_page with storage guikit:work
scoreboard players set #i guikit.tmp 0
function guikit:editor/edit/placeholders
function guikit:editor/edit/draw_loop
function guikit:editor/edit/tools_button
