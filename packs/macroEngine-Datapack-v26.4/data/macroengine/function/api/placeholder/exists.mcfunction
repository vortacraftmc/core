# macroengine:api/placeholder/exists [MACRO]
# RETURN 1 when %name% is registered, else 0. Input (macro arg): name
$return run execute if data storage macroengine:placeholder reg.$(name)
