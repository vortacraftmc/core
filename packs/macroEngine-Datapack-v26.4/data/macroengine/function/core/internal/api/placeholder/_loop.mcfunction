# macroengine:core/internal/api/placeholder/_loop [INTERNAL]
# Walks segs, which alternate text, name, text, name ... #ph_name is 0 when the
# head is plain text and 1 when it is a name between two '%' signs.
execute unless data storage macroengine:placeholder segs[0] run return 0
execute if score #ph_name macroengine.tmp matches 0 run function macroengine:core/internal/api/placeholder/_step_text
# _step_text may have consumed the last segment. Without this guard _step_name would run
# on an empty list and append a stray literal '%' to the output (e.g. "Coin: 5%").
execute unless data storage macroengine:placeholder segs[0] run return 0
execute if score #ph_name macroengine.tmp matches 1 run function macroengine:core/internal/api/placeholder/_step_name
function macroengine:core/internal/api/placeholder/_loop
