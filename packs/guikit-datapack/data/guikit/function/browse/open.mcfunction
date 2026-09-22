function guikit:runtime/ensure_pid
data remove storage guikit:ed pending
data modify storage guikit:ed pending set value {mode:"browse",menu:"-",alias:"browse"}
function guikit:internal/clear/in
data merge storage guikit:in {menu:"guikit:browse",timer:6000}
function guikit:api/open
data remove storage guikit:ed pending
execute unless score #ok guikit.const matches 1 run tellraw @s {"text":"[guikit] Could not open the menu list.","color":"red"}
