# macroengine:api/placeholder/give [MACRO]
# Gives @s an item whose name and lore come from placeholder text. Lines are split
# at %nl%; names and lore are not italic unless the text says so.
#
# Input: macroengine:placeholder in — text with %placeholders%
#        macro arg: item (an item id)
#
# Usage:
#   data modify storage macroengine:placeholder in set value "%player%'s sword%nl%Kills: %score:kills%"
#   function macroengine:api/placeholder/give {item:"minecraft:iron_sword"}
$data modify storage macroengine:placeholder item set value "$(item)"
function macroengine:api/placeholder/parse
function macroengine:core/internal/api/placeholder/_give with storage macroengine:placeholder
