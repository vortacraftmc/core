# macroengine:core/internal/api/placeholder/_wrap_string [INTERNAL]
# cur (string) -> {text:<string>}
data modify storage macroengine:placeholder wrap set value {text:""}
data modify storage macroengine:placeholder wrap.text set from storage macroengine:placeholder cur
data modify storage macroengine:placeholder cur set from storage macroengine:placeholder wrap
data remove storage macroengine:placeholder wrap
