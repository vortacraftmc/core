# macroengine:api/placeholder/register_array [MACRO]
# Registers %name% as an array of parts. Each element may be a string, a text
# component or a nested array. The parts are shown one after another; no element
# styles the others, so [{text:"A",color:"red"},"B"] shows a red A and a plain B.
#
# Input: macroengine:placeholder in.array — non-empty array
#        macro arg: name
# RETURN 1 when registered, 0 when in.array is missing or empty.
#
# Usage:
#   data modify storage macroengine:placeholder in.array set value [{text:"[",color:"gray"},{selector:"@s",color:"white"},{text:"]",color:"gray"}]
#   function macroengine:api/placeholder/register_array {name:"tag"}
execute unless data storage macroengine:placeholder in.array[] run return 0
$data modify storage macroengine:placeholder reg.$(name) set from storage macroengine:placeholder in.array
return 1
