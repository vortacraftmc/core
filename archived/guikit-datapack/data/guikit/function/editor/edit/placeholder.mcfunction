# macro: $(i)
scoreboard players set #lock guikit.tmp 0
$execute if score #limit guikit.tmp matches ..$(i) run scoreboard players set #lock guikit.tmp 1
execute if score #lock guikit.tmp matches 1.. run function guikit:editor/edit/placeholder_lock with storage guikit:work
execute if score #lock guikit.tmp matches 0 run function guikit:editor/edit/placeholder_open with storage guikit:work
