# macroEngine string module — split: reversed loop entry (negative n).
# Called from util/split with storage temp data{Min, Max} where Max = index
# of the LAST separator occurrence. Processes separators right-to-left:
# the rightmost pop only marks the tail boundary (the caller emits the tail
# via last_segment); every further pop emits the segment between two
# separators by inserting it at the FRONT of the output list, so final order
# stays left-to-right.

# Normalize n: unset/0/negative => split at every occurrence
execute if score #StringLib.FindAmount StringLib matches ..0 run scoreboard players set #StringLib.FindAmount StringLib 2147483647

# Pop the rightmost separator: it bounds the trailing remainder
data remove storage macroengine:core/internal/string/output find[-1]
scoreboard players remove #StringLib.FindAmount StringLib 1

# Min = start of the trailing remainder (emitted later by the caller)
scoreboard players operation #StringLib.Min StringLib = #StringLib.Max StringLib
scoreboard players operation #StringLib.Min StringLib += #StringLib.SeparatorLength StringLib
execute store result storage macroengine:core/internal/string/temp data.Min int 1 run scoreboard players get #StringLib.Min StringLib

# RightBound = index of the separator to the right of the next segment
scoreboard players operation #StringLib.RightBound StringLib = #StringLib.Max StringLib
execute store result storage macroengine:core/internal/string/temp data.RightBound int 1 run scoreboard players get #StringLib.RightBound StringLib

# Process the remaining (more left-ward) separators, if any and if n allows it
execute if data storage macroengine:core/internal/string/output find[] if score #StringLib.FindAmount StringLib matches 1.. run function macroengine:core/internal/string/zprivate/split/reversed/step with storage macroengine:core/internal/string/temp data

# Emit the head segment String[0..RightBound) at the front of the output
execute store result storage macroengine:core/internal/string/temp data.HeadEnd int 1 run scoreboard players get #StringLib.RightBound StringLib
$data modify storage macroengine:core/internal/string/temp data.Segment set string storage macroengine:core/internal/string/input split.String 0 $(HeadEnd)
execute if score #StringLib.KeepEmpty StringLib matches 1 run data modify storage macroengine:core/internal/string/output split insert 0 from storage macroengine:core/internal/string/temp data.Segment
execute unless score #StringLib.KeepEmpty StringLib matches 1 if score #StringLib.RightBound StringLib matches 1.. run data modify storage macroengine:core/internal/string/output split insert 0 from storage macroengine:core/internal/string/temp data.Segment
