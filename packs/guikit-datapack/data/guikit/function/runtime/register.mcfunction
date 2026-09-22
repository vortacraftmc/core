# guikit :: runtime/register     #guikit:register, after the built-in containers
# Menus authored in-game live in storage guikit:lib (world save). The registry is rebuilt every reload.
data modify storage guikit:reg containers.gk_editor set value {entity:"chest_minecart",slots:27,pad:"minecraft:black_stained_glass_pane",title:{text:"GUI Editor",color:"gold",italic:false}}
data modify storage guikit:reg menus."guikit:editor" set value {alias:"editor",container:"gk_editor"}
data modify storage guikit:reg containers.gk_browse set value {entity:"chest_minecart",slots:27,pad:"minecraft:gray_stained_glass_pane",title:{text:"Menus",italic:false}}
data modify storage guikit:reg menus."guikit:browse" set value {alias:"browse",container:"gk_browse"}

execute unless data storage guikit:lib order run data modify storage guikit:lib order set value []
execute unless data storage guikit:lib menus run data modify storage guikit:lib menus set value {}
execute unless data storage guikit:lib seeded run function guikit:runtime/seed
function guikit:runtime/sync
data remove storage guikit:ed pending
