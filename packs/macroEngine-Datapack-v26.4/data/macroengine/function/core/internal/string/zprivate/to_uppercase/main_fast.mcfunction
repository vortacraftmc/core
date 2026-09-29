# macroEngine string module — uppercase (fast) per-character loop.
# Logic after CMDred's StringLib algorithm (A-Z only, reverse lookup),
# re-implemented for macroengine storage paths. Expects storage temp data{Input, Char}.

# Ensure the output buffer exists (first call only)
execute unless data storage macroengine:core/internal/string/temp data.CharList run data modify storage macroengine:core/internal/string/temp data.CharList set value []

# Convert current character to uppercase (& handle a character having 2 possible outputs)
data remove storage macroengine:core/internal/string/temp data.List
$data modify storage macroengine:core/internal/string/temp data.List append from storage macroengine:core/internal/string/zprivate data.CharMap.Fast[{l:"$(Char)"}].u
data modify storage macroengine:core/internal/string/temp data.CharList append from storage macroengine:core/internal/string/temp data.List[0]
execute unless data storage macroengine:core/internal/string/temp data.List run data modify storage macroengine:core/internal/string/temp data.CharList append from storage macroengine:core/internal/string/temp data.Char

# Next loop
execute if score #StringLib.CharsLeft StringLib matches 1 run return 0
scoreboard players remove #StringLib.CharsLeft StringLib 1
data modify storage macroengine:core/internal/string/temp data.Input set string storage macroengine:core/internal/string/temp data.Input 1
data modify storage macroengine:core/internal/string/temp data.Char set string storage macroengine:core/internal/string/temp data.Input 0 1
function macroengine:core/internal/string/zprivate/to_uppercase/main_fast with storage macroengine:core/internal/string/temp data
