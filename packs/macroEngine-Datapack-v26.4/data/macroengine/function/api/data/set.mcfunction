# macroengine:api/data/set [MACRO]
# Writes macroengine:data value to storage/path. Input (macro args): storage, path
# Passing the value through storage means any SNBT is safe: no escaping needed.
#
# Usage:
#   data modify storage macroengine:data value set value {hp:20,name:"Steve"}
#   function macroengine:api/data/set {storage:"mypack:data",path:"players.steve"}
$data modify storage $(storage) $(path) set from storage macroengine:data value
