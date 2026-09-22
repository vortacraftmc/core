# guikit :: editor/create
function guikit:editor/load_state
execute unless score #next_menu guikit.const matches 1.. run scoreboard players set #next_menu guikit.const 1
execute store result storage guikit:work n int 1 run scoreboard players get #next_menu guikit.const
scoreboard players add #next_menu guikit.const 1
function guikit:editor/create_do with storage guikit:work
