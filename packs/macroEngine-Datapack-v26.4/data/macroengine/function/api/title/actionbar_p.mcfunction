# macroengine:api/title/actionbar_p
# Placeholder-aware action bar for @s.
# INPUT macroengine:title in.text — string with %placeholders%
#
# Usage:
#   data modify storage macroengine:title in set value {text:"HP %score:hp% | %player%"}
#   function macroengine:api/title/actionbar_p
data modify storage macroengine:placeholder in set value ""
execute if data storage macroengine:title in.text run data modify storage macroengine:placeholder in set from storage macroengine:title in.text
function macroengine:api/placeholder/actionbar
