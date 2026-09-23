# macro: $(id)
$execute unless data storage guikit:lib menus.$(id) run tellraw @s {"text":"[guikit] That menu does not exist.","color":"red"}
$execute unless data storage guikit:lib menus.$(id) run return 0
$execute unless data storage guikit:reg menus."guikit:m/$(id)" run function guikit:runtime/sync_one {id:"$(id)"}
function guikit:internal/clear/in
$data merge storage guikit:in {menu:"guikit:m/$(id)"}
$execute store result storage guikit:in timer int 1 run data get storage guikit:lib menus.$(id).timer
execute unless data storage guikit:in timer run data modify storage guikit:in timer set value 900
data remove storage guikit:ed pending
data modify storage guikit:ed pending set value {mode:"play",menu:"-",alias:"gkm_0"}
$data modify storage guikit:ed pending.menu set value "$(id)"
$function guikit:play/pending_alias {id:"$(id)"}
function guikit:api/open
data remove storage guikit:ed pending
execute unless score #ok guikit.const matches 1 run tellraw @s {"text":"[guikit] Could not open that menu.","color":"red"}
# v5: remember it for /trigger guikit.last (pid is assigned by play/open_id before this runs)
$execute if score #ok guikit.const matches 1 run function guikit:play/last_record {id:"$(id)"}
