# macroengine:api/placeholder/_step_name [INTERNAL]
# The head follows an opening '%'. It is a placeholder only when a closing '%'
# exists, i.e. another segment follows. Otherwise "%" + head is kept as text.
scoreboard players set #ph_name macroengine.tmp 0
execute unless data storage macroengine:placeholder segs[1] run data modify storage macroengine:placeholder cur set value {text:"%"}
execute unless data storage macroengine:placeholder segs[1] run data modify storage macroengine:placeholder out append from storage macroengine:placeholder cur
execute unless data storage macroengine:placeholder segs[1] run return run function macroengine:api/placeholder/_step_text
function macroengine:api/placeholder/_resolve
data remove storage macroengine:placeholder segs[0]
