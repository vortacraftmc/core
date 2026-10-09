# macroengine:api/data/exists [MACRO]
# RETURN 1 when storage/path exists, else 0. Input (macro args): storage, path
$return run execute if data storage $(storage) $(path)
