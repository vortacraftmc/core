# macroEngine string module — split: final tidy-up.
# Called from util/split after all segments were emitted. Removes the
# split-scoped scratch fields; util/split then wipes temp data entirely and
# restores the find input/output it borrowed.

data remove storage macroengine:core/internal/string/temp data.Segment
data remove storage macroengine:core/internal/string/temp data.Min
data remove storage macroengine:core/internal/string/temp data.Max
data remove storage macroengine:core/internal/string/temp data.RightBound
data remove storage macroengine:core/internal/string/temp data.SegStart
data remove storage macroengine:core/internal/string/temp data.HeadEnd
