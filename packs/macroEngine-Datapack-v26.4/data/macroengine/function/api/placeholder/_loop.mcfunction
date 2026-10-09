# macroengine:api/placeholder/_loop [INTERNAL]
# Walks segs, which alternate text, name, text, name ... #ph_name is 0 when the
# head is plain text and 1 when it is a name between two '%' signs.
execute unless data storage macroengine:placeholder segs[0] run return 0
execute if score #ph_name macroengine.tmp matches 0 run function macroengine:api/placeholder/_step_text
execute if score #ph_name macroengine.tmp matches 1 run function macroengine:api/placeholder/_step_name
function macroengine:api/placeholder/_loop
