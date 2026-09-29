# macroEngine string module — split: emit the trailing segment after the last
# processed separator. Macro function, expects storage temp data{Min} where
# Min = start index of the trailing remainder.

execute store result score #StringLib.Min StringLib run data get storage macroengine:core/internal/string/temp data.Min
$data modify storage macroengine:core/internal/string/temp data.Segment set string storage macroengine:core/internal/string/input split.String $(Min)
execute if score #StringLib.KeepEmpty StringLib matches 1 run data modify storage macroengine:core/internal/string/output split append from storage macroengine:core/internal/string/temp data.Segment
execute unless score #StringLib.KeepEmpty StringLib matches 1 if score #StringLib.Min StringLib < #StringLib.CharsTotal StringLib run data modify storage macroengine:core/internal/string/output split append from storage macroengine:core/internal/string/temp data.Segment
