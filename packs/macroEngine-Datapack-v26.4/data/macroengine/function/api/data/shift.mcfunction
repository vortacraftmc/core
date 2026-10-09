# macroengine:api/data/shift [MACRO]
# Removes the FIRST element of the list at storage/path (queue behaviour) into macroengine:data result.
# Input (macro args): storage, path.  RETURN 1 when an element was removed, 0 otherwise.
data remove storage macroengine:data result
$execute unless data storage $(storage) $(path)[0] run return 0
$data modify storage macroengine:data result set from storage $(storage) $(path)[0]
$data remove storage $(storage) $(path)[0]
return 1
