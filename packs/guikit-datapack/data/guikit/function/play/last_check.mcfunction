# guikit :: play/last_check   macro: $(last)
# The remembered id may point at a menu that was deleted since. Check against guikit:lib, then open.
$execute unless data storage guikit:lib menus.$(last) run tellraw @s {"text":"[guikit] That menu does not exist anymore.","color":"red"}
$execute unless data storage guikit:lib menus.$(last) run return 0
$function guikit:play/open_id {menu:"$(last)"}
