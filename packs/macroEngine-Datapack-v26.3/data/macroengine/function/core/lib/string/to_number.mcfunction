# macroengine:core/lib/string/to_number
# Input:  macroengine:input string — numeric string (e.g. "42" or "3.14")
# Output: macroengine:output string.result — numeric NBT value
# Dep:    StringLib (CMDred)
data modify storage macroengine:engine _str_bridge.Input set from storage macroengine:input string
function macroengine:core/internal/core/lib/string/to_number_dispatch with storage macroengine:engine _str_bridge
data modify storage macroengine:output string.result set from storage macroengine:core/internal/string/output to_number
data remove storage macroengine:core/internal/string/output to_number
data remove storage macroengine:engine _str_bridge
# # tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_string_to_number","color":"aqua"}]
