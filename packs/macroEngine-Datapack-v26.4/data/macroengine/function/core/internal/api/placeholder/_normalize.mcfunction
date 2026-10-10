# macroengine:core/internal/api/placeholder/_normalize [INTERNAL]
# `cur` holds a registered value. Turns it into one self-contained text component:
#   compound -> kept as is (the original text component support)
#   string   -> {text:<string>}
#   array    -> {text:"",extra:<array>}  (every element is a child of an empty parent,
#               so the first element does not become the style parent of the others)
#   empty string / empty array -> {text:""}
# Values are only copied with `set from`, never substituted into a command.
execute if data storage macroengine:placeholder cur{} run return 0
execute if data storage macroengine:placeholder cur[] run return run function macroengine:core/internal/api/placeholder/_wrap_array
execute store result score #ph_len macroengine.tmp run data get storage macroengine:placeholder cur
execute if score #ph_len macroengine.tmp matches 0 run data modify storage macroengine:placeholder cur set value {text:""}
execute if score #ph_len macroengine.tmp matches 0 run return 0
function macroengine:core/internal/api/placeholder/_wrap_string
