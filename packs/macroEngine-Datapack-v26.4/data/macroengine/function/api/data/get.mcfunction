# macroengine:api/data/get [MACRO]
# Reads one NBT value into macroengine:data result.
# Input (macro args): storage (e.g. "mypack:data"), path (e.g. "player.stats")
# RETURN 1 when the path exists (result set), 0 otherwise (result removed).
#
# Usage:  function macroengine:api/data/get {storage:"mypack:data",path:"motd"}
data remove storage macroengine:data result
$execute unless data storage $(storage) $(path) run return 0
$data modify storage macroengine:data result set from storage $(storage) $(path)
return 1
