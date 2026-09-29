# macroEngine string module — split: separator is "" -> split every character.
# Called via `return run` from util/split. Returns the element count.
# Note: util/split early-returns from inside this call, so this function must
# clean up temp data itself.

execute store result score #StringLib.CharsLeft StringLib run data get storage macroengine:core/internal/string/input split.String
data modify storage macroengine:core/internal/string/temp data.Rest set from storage macroengine:core/internal/string/input split.String
data modify storage macroengine:core/internal/string/temp data.CharList set value []

function macroengine:core/internal/string/zprivate/split/split_chars/loop

data modify storage macroengine:core/internal/string/output split set from storage macroengine:core/internal/string/temp data.CharList
data remove storage macroengine:core/internal/string/temp data

return run execute if data storage macroengine:core/internal/string/output split[]
