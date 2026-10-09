# macroengine:api/data/count [MACRO]
# RETURN the length of the list/string or the number of keys of the compound at
# storage/path (0 when missing). Input (macro args): storage, path
$execute unless data storage $(storage) $(path) run return 0
$return run data get storage $(storage) $(path)
