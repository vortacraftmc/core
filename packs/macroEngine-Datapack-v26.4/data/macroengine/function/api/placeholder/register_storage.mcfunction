# macroengine:api/placeholder/register_storage [MACRO]
# Registers %name% as an NBT value read from a command storage. Rendered with
# plain+interpret=false so strings have no quotes and numbers no type colouring.
#
# Input (macro args): name, storage (e.g. "mypack:data"), path (e.g. "motd")
#
# Usage:
#   function macroengine:api/placeholder/register_storage {name:"motd",storage:"mypack:data",path:"motd"}
$data modify storage macroengine:placeholder reg.$(name) set value {storage:"$(storage)",nbt:"$(path)",plain:true,interpret:false}
