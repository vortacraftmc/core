# macroEngine string module — split: reversed loop step.
# Macro function, expects storage temp data{RightBound}. Pops the rightmost
# remaining separator f, emits String[f+SeparatorLength..RightBound) at the
# front of the output list, then continues leftwards.

# f = rightmost remaining separator index
execute store result score #StringLib.Max StringLib run data get storage macroengine:core/internal/string/output find[-1]
scoreboard players operation #StringLib.SegStart StringLib = #StringLib.Max StringLib
scoreboard players operation #StringLib.SegStart StringLib += #StringLib.SeparatorLength StringLib
execute store result storage macroengine:core/internal/string/temp data.SegStart int 1 run scoreboard players get #StringLib.SegStart StringLib

# Emit String[f+L..RightBound) at the front
$data modify storage macroengine:core/internal/string/temp data.Segment set string storage macroengine:core/internal/string/input split.String $(SegStart) $(RightBound)
execute if score #StringLib.KeepEmpty StringLib matches 1 run data modify storage macroengine:core/internal/string/output split insert 0 from storage macroengine:core/internal/string/temp data.Segment
execute unless score #StringLib.KeepEmpty StringLib matches 1 if score #StringLib.SegStart StringLib < #StringLib.RightBound StringLib run data modify storage macroengine:core/internal/string/output split insert 0 from storage macroengine:core/internal/string/temp data.Segment

# Consume the separator; it becomes the new right boundary; track Min
data remove storage macroengine:core/internal/string/output find[-1]
scoreboard players remove #StringLib.FindAmount StringLib 1
scoreboard players operation #StringLib.RightBound StringLib = #StringLib.Max StringLib
execute store result storage macroengine:core/internal/string/temp data.RightBound int 1 run scoreboard players get #StringLib.RightBound StringLib
scoreboard players operation #StringLib.Min StringLib = #StringLib.SegStart StringLib
execute store result storage macroengine:core/internal/string/temp data.Min int 1 run scoreboard players get #StringLib.Min StringLib

# Continue leftwards?
execute if data storage macroengine:core/internal/string/output find[] if score #StringLib.FindAmount StringLib matches 1.. run function macroengine:core/internal/string/zprivate/split/reversed/step with storage macroengine:core/internal/string/temp data
