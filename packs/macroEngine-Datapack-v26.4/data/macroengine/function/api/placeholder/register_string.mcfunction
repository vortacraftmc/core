# macroengine:api/placeholder/register_string [MACRO]
# Registers %name% as a plain string. Unlike register_text the value is read from
# storage, so it may contain double quotes, backslashes or braces without any escaping.
#
# Input: macroengine:placeholder in.string — the string to show
#        macro arg: name
# RETURN 1 when registered, 0 when in.string is missing.
#
# Usage:
#   data modify storage macroengine:placeholder in.string set value "Say \"hi\" to {everyone}"
#   function macroengine:api/placeholder/register_string {name:"greeting"}
execute unless data storage macroengine:placeholder in.string run return 0
$data modify storage macroengine:placeholder reg.$(name) set from storage macroengine:placeholder in.string
return 1
