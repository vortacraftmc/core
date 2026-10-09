# macroengine:api/data/copy [MACRO]
# Copies one NBT value to another place.
# Input (macro args): from, from_path, to, to_path   (from/to are storage ids)
#
# Usage:  function macroengine:api/data/copy {from:"a:b",from_path:"x",to:"c:d",to_path:"y"}
$data modify storage $(to) $(to_path) set from storage $(from) $(from_path)
