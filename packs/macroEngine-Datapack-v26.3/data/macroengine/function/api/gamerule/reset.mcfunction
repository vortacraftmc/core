# macroengine:api/gamerule/reset [MACRO]
# Removes a custom gamerule from engine storage entirely.
# Does NOT touch vanilla /gamerule — this is for macroengine-tracked rules only.
#
# INPUT (macro args via `with storage macroengine:input {}`):
#   $(rule) — rule name string
#
# EXAMPLE:
#   data modify storage macroengine:input rule set value "pvp_enabled"
#   function macroengine:api/gamerule/reset with storage macroengine:input {}


# Normalize
data modify storage macroengine:core/internal/string/input replace.String set from storage macroengine:input rule
data modify storage macroengine:core/internal/string/input replace.Find set value " "
data modify storage macroengine:core/internal/string/input replace.Replace set value "_"
function macroengine:core/internal/string/util/replace
data modify storage macroengine:input _gamerule_norm set from storage macroengine:core/internal/string/output replace
data remove storage macroengine:core/internal/string/input replace

function macroengine:core/internal/api/gamerule/remove with storage macroengine:input {}

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.gamerule_reset","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(_gamerule_norm)","color":"gray","italic":true},{"translate":"macroengine.ui.removed","color":"gray"}]

data remove storage macroengine:input _gamerule_norm
