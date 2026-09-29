# macroEngine string module — split: per-character loop for split_chars.
# Walks temp data.Rest one character at a time into temp data.CharList.

data modify storage macroengine:core/internal/string/temp data.Char set string storage macroengine:core/internal/string/temp data.Rest 0 1
data modify storage macroengine:core/internal/string/temp data.CharList append from storage macroengine:core/internal/string/temp data.Char

execute if score #StringLib.CharsLeft StringLib matches 1 run return 0
scoreboard players remove #StringLib.CharsLeft StringLib 1
data modify storage macroengine:core/internal/string/temp data.Rest set string storage macroengine:core/internal/string/temp data.Rest 1
function macroengine:core/internal/string/zprivate/split/split_chars/loop
