execute store result storage guikit:work pid int 1 run scoreboard players get @s guikit.pid
data modify storage guikit:work key set from storage guikit:work w.key
execute store result storage guikit:work delta int 1 run data get storage guikit:work w.delta
execute store result storage guikit:work max int 1 run data get storage guikit:work w.max
execute unless data storage guikit:work delta run data modify storage guikit:work delta set value 1
execute unless data storage guikit:work max run data modify storage guikit:work max set value 99
function guikit:play/act/add_do with storage guikit:work
scoreboard players set @s guikit.dirty 1
