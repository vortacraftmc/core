# macroEngine string module — split: forward loop.
# Re-implemented for macroengine. Called from util/split with storage temp
# data{Min, Max} where Max = index of the next separator occurrence.
# Emits String[Min..Max), consumes find[0], then recurses over the remaining
# separator indices. #StringLib.FindAmount holds n (already normalized:
# <=0 became 2147483647 = "split at all occurrences").

# Sync Min score with storage (entry may come with score unset)
execute store result score #StringLib.Min StringLib run data get storage macroengine:core/internal/string/temp data.Min

# Normalize n: unset/0/negative => split at every occurrence
execute if score #StringLib.FindAmount StringLib matches ..0 run scoreboard players set #StringLib.FindAmount StringLib 2147483647

# Emit the segment String[Min..Max)
$data modify storage macroengine:core/internal/string/temp data.Segment set string storage macroengine:core/internal/string/input split.String $(Min) $(Max)
execute if score #StringLib.KeepEmpty StringLib matches 1 run data modify storage macroengine:core/internal/string/output split append from storage macroengine:core/internal/string/temp data.Segment
execute unless score #StringLib.KeepEmpty StringLib matches 1 if score #StringLib.Min StringLib < #StringLib.Max StringLib run data modify storage macroengine:core/internal/string/output split append from storage macroengine:core/internal/string/temp data.Segment

# Consume this separator occurrence and advance Min past it
data remove storage macroengine:core/internal/string/output find[0]
scoreboard players operation #StringLib.Min StringLib += #StringLib.SeparatorLength StringLib
execute store result storage macroengine:core/internal/string/temp data.Min int 1 run scoreboard players get #StringLib.Min StringLib
scoreboard players remove #StringLib.FindAmount StringLib 1

# Continue with the next separator, if any and if n allows it.
# #StringLib.Max / data.Max stay on the last processed separator index;
# the caller adds SeparatorLength to reach the trailing remainder.
execute if data storage macroengine:core/internal/string/output find[] if score #StringLib.FindAmount StringLib matches 1.. run function macroengine:core/internal/string/zprivate/split/main_next
