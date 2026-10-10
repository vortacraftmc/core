# macroengine:core/internal/api/placeholder/_save [INTERNAL]
# Mirrors the last parse into macroengine:output placeholder so callers can read the
# result with the same storage the other API modules use.
#   placeholder.in   the input string (absent when parse had no input)
#   placeholder.out  the resolved component list
#   placeholder.string       the same list as an SNBT string
#   placeholder.custom_name  ready for custom_name= (see _derive)
#   placeholder.lore         ready for lore= (see _derive)
#   placeholder.reg  snapshot of the registered placeholders (absent when none)
function macroengine:core/internal/api/placeholder/_derive

data remove storage macroengine:output placeholder.in
data remove storage macroengine:output placeholder.reg
data modify storage macroengine:output placeholder.out set value []
execute if data storage macroengine:placeholder in run data modify storage macroengine:output placeholder.in set from storage macroengine:placeholder in
execute if data storage macroengine:placeholder out run data modify storage macroengine:output placeholder.out set from storage macroengine:placeholder out
data modify storage macroengine:output placeholder.string set from storage macroengine:placeholder string
data modify storage macroengine:output placeholder.custom_name set from storage macroengine:placeholder custom_name
data modify storage macroengine:output placeholder.lore set from storage macroengine:placeholder lore
execute if data storage macroengine:placeholder reg run data modify storage macroengine:output placeholder.reg set from storage macroengine:placeholder reg
return 0
