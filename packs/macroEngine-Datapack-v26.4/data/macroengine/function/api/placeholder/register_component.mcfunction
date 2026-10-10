# macroengine:api/placeholder/register_component [MACRO]
# Registers %name% as an arbitrary text component (colours, hover, click,
# translate, gradients ...). The component is read from storage, so it needs no
# string escaping at all. A plain string (any characters, no escaping) or an array of
# strings/components is accepted too; each is wrapped into one component when the
# placeholder is resolved (see core/internal/api/placeholder/_normalize).
#
# Input: macroengine:placeholder in.component — any SNBT text component, string or array
#        macro arg: name
#
# Usage:
#   data modify storage macroengine:placeholder in.component set value {text:"VIP",color:"gold",bold:true}
#   function macroengine:api/placeholder/register_component {name:"rank"}
$data modify storage macroengine:placeholder reg.$(name) set from storage macroengine:placeholder in.component
