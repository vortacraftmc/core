# macroEngine string module — split: forward loop step (non-macro trampoline).
# Loads the next separator index into data.Max / #StringLib.Max and re-enters
# the macro loop. Exists because `function ... with storage` needs the fresh
# Max value staged in storage first.

execute store result storage macroengine:core/internal/string/temp data.Max int 1 store result score #StringLib.Max StringLib run data get storage macroengine:core/internal/string/output find[0]
function macroengine:core/internal/string/zprivate/split/main with storage macroengine:core/internal/string/temp data
