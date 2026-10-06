# Copy the widget in cur.slot into guikit:ed widget. #ok = 1 if that slot has one.
scoreboard players set #ok guikit.tmp 0
function guikit:editor/read_menu
execute store result storage guikit:work page int 1 run data get storage guikit:ed cur.page
function guikit:editor/edit/load_src with storage guikit:work
function guikit:editor/ui/load_widget_loop
