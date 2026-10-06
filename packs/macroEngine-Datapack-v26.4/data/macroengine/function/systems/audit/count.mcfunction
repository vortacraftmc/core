# macroengine:systems/audit/count
# Number of stored audit entries (0..100).
# Output: macroengine:output result (int) and the function return value.
#
# Usage:  function macroengine:systems/audit/count

execute store result score #macroengine.au_c macroengine.tmp run data get storage macroengine:audit entries
execute store result storage macroengine:output result int 1 run scoreboard players get #macroengine.au_c macroengine.tmp
return run scoreboard players get #macroengine.au_c macroengine.tmp
