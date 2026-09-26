# macroengine:core/lib/string/to_lowercase
# Fast variant — covers A-Z only (faster)
# Input:  macroengine:input string — string to convert
# Output: macroengine:output string.result — lowercase string
# Dep:    StringLib (CMDred)
data modify storage macroengine:engine _str_bridge.String set from storage macroengine:input string
function macroengine:core/internal/core/lib/string/to_lower_fast_dispatch with storage macroengine:engine _str_bridge
data modify storage macroengine:output string.result set from storage macroengine:core/internal/string/output to_lowercase
data remove storage macroengine:core/internal/string/output to_lowercase
data remove storage macroengine:engine _str_bridge
# # tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_string_to_lowercase","color":"aqua"}]
