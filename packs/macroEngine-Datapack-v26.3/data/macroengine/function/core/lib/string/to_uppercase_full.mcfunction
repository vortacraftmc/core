# macroengine:core/lib/string/to_uppercase_full
# Full variant — covers full Unicode lowercase mapping (slower)
# Input:  macroengine:input string — string to convert
# Output: macroengine:output string.result — uppercase string
# Dep:    StringLib (CMDred)
data modify storage macroengine:engine _str_bridge.String set from storage macroengine:input string
function macroengine:core/internal/core/lib/string/to_upper_full_dispatch with storage macroengine:engine _str_bridge
data modify storage macroengine:output string.result set from storage macroengine:core/internal/string/output to_uppercase
data remove storage macroengine:core/internal/string/output to_uppercase
data remove storage macroengine:engine _str_bridge
# # tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_string_to_uppercase_full","color":"aqua"}]
