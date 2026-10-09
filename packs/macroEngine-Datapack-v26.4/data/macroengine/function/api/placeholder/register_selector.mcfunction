# macroengine:api/placeholder/register_selector [MACRO]
# Registers %name% as an entity/player name via a selector.
#
# Input (macro args): name, selector (e.g. "@p", "@s", "Steve")
#
# Usage:
#   function macroengine:api/placeholder/register_selector {name:"nearest",selector:"@p"}
$data modify storage macroengine:placeholder reg.$(name) set value {selector:"$(selector)"}
