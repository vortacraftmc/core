# macroengine:core/lib/string/to_string
# Input:  macroengine:input value — numeric or any SNBT value to stringify
# Output: macroengine:output string.result — string representation
# Note:   Prefer 'data modify ... set string storage ...' when possible (cheaper)
# Dep:    StringLib (CMDred)
data modify storage macroengine:engine _str_bridge.Input set from storage macroengine:input value
function macroengine:core/internal/core/lib/string/to_string_dispatch with storage macroengine:engine _str_bridge
data modify storage macroengine:output string.result set from storage macroengine:core/internal/string/output to_string
data remove storage macroengine:core/internal/string/output to_string
data remove storage macroengine:engine _str_bridge
# # tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_string_to_string","color":"aqua"}]
