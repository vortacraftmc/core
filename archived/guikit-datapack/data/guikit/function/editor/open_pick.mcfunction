# guikit :: editor/open_pick     as player, at player
function guikit:editor/save_state
data modify storage guikit:reg containers.gk_editor.title set value {text:"Pick a menu",color:"aqua",italic:false}
data remove storage guikit:ed pending
data modify storage guikit:ed pending set value {mode:"pick",menu:"-",alias:"editor"}
function guikit:internal/clear/in
data merge storage guikit:in {menu:"guikit:editor",timer:6000}
function guikit:api/open
data remove storage guikit:ed pending
execute if score #ok guikit.const matches 1 run tellraw @s {"text":"[guikit] Click the menu this button should open.","color":"gray"}
