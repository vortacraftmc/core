# macroengine:api/data/pop [MACRO]
# Removes the LAST element of the list at storage/path and puts it in macroengine:data result.
# Input (macro args): storage, path.  RETURN 1 when an element was popped, 0 for an empty/missing list.
data remove storage macroengine:data result
$execute unless data storage $(storage) $(path)[-1] run return 0
$data modify storage macroengine:data result set from storage $(storage) $(path)[-1]
$data remove storage $(storage) $(path)[-1]
return 1
