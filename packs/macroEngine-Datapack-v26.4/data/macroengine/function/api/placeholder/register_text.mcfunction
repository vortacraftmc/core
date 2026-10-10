# macroengine:api/placeholder/register_text [MACRO]
# Registers %name% as a fixed piece of text.
#
# Input (macro args):
#   name  — placeholder name, without the percent signs (letters, digits, _ - .)
#   value — text to substitute (must not contain a double quote or backslash;
#           use register_component for text that does)
#
# Usage:
#   function macroengine:api/placeholder/register_text {name:"server",value:"My Server"}
$data modify storage macroengine:placeholder reg.$(name) set value {text:"$(value)"}
