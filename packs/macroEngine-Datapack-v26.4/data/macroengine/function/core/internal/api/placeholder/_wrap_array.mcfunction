# macroengine:core/internal/api/placeholder/_wrap_array [INTERNAL]
# cur (non-empty array of strings / components / arrays) -> {text:"",extra:<array>}
data modify storage macroengine:placeholder wrap set value {text:""}
data modify storage macroengine:placeholder wrap.extra set from storage macroengine:placeholder cur
data modify storage macroengine:placeholder cur set from storage macroengine:placeholder wrap
data remove storage macroengine:placeholder wrap
