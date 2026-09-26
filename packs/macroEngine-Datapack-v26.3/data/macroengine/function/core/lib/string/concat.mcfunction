# macroengine:core/lib/string/concat
# Input:  macroengine:input list   — list of strings to concatenate
# Output: macroengine:output string.result — combined string
# Dep:    StringLib (CMDred)
data modify storage macroengine:core/internal/string/input concat set from storage macroengine:input list
function macroengine:core/internal/string/util/concat
data modify storage macroengine:output string.result set from storage macroengine:core/internal/string/output concat
data remove storage macroengine:core/internal/string/input concat
data remove storage macroengine:core/internal/string/output concat
# # tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_string_concat","color":"aqua"}]
