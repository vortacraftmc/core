# macroengine:core/internal/api/placeholder/_save [INTERNAL]
# Mirrors the last parse into macroengine:output placeholder so callers can read the
# result with the same storage the other API modules use.
#   placeholder.in   the input string (absent when parse had no input)
#   placeholder.out  the resolved component list
#   placeholder.reg  snapshot of the registered placeholders (absent when none)
data remove storage macroengine:output placeholder.in
data remove storage macroengine:output placeholder.reg
data modify storage macroengine:output placeholder.out set value []
execute if data storage macroengine:placeholder in run data modify storage macroengine:output placeholder.in set from storage macroengine:placeholder in
execute if data storage macroengine:placeholder out run data modify storage macroengine:output placeholder.out set from storage macroengine:placeholder out
execute if data storage macroengine:placeholder reg run data modify storage macroengine:output placeholder.reg set from storage macroengine:placeholder reg
return 0
