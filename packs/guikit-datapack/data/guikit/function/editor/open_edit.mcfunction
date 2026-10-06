# guikit :: editor/open_edit     as player, at player
function guikit:editor/save_state
function guikit:editor/read_menu
execute unless data storage guikit:work menu run tellraw @s {"text":"[guikit] That menu no longer exists.","color":"red"}
execute unless data storage guikit:work menu run return run function guikit:editor/open_home
data modify storage guikit:reg containers.gk_editor.title set value {text:"Edit",color:"gold",italic:false}
data modify storage guikit:reg containers.gk_editor.title.text set from storage guikit:work menu.name
data remove storage guikit:ed pending
data modify storage guikit:ed pending set value {mode:"edit",menu:"-",alias:"editor"}
data modify storage guikit:ed pending.menu set from storage guikit:ed cur.menu
function guikit:internal/clear/in
data merge storage guikit:in {menu:"guikit:editor",timer:6000}
function guikit:api/open
data remove storage guikit:ed pending
execute if score #ok guikit.const matches 1 run tellraw @s [{"text":"[guikit] Editing ","color":"gray"},{"nbt":"menu.name","storage":"guikit:work","interpret":false,"color":"gold"},{"text":". Bottom-right is Tools, not part of the menu.","color":"gray"}]
