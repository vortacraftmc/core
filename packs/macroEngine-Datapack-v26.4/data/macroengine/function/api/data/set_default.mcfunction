# macroengine:api/data/set_default [MACRO]
# Writes macroengine:data value to storage/path ONLY when the path does not exist yet
# (first-run initialisation that never overwrites live data).
# Input (macro args): storage, path.  RETURN 1 when it wrote, 0 when it already existed.
$execute if data storage $(storage) $(path) run return 0
$data modify storage $(storage) $(path) set from storage macroengine:data value
return 1
