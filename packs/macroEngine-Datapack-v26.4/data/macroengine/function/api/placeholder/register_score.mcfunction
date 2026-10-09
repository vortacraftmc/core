# macroengine:api/placeholder/register_score [MACRO]
# Registers %name% as a scoreboard value. holder may be a selector such as @s
# (resolved for whoever the text is shown to) or a fake player such as #total.
#
# Input (macro args): name, holder, objective
#
# Usage:
#   function macroengine:api/placeholder/register_score {name:"kills",holder:"@s",objective:"kills"}
$data modify storage macroengine:placeholder reg.$(name) set value {score:{name:"$(holder)",objective:"$(objective)"}}
