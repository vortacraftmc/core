# macroengine:core/internal/api/placeholder/_plain_loop [INTERNAL]
# Walks _rest, adding one string per component to _parts.
execute unless data storage macroengine:placeholder _rest[0] run return 0
data remove storage macroengine:placeholder _piece
execute if data storage macroengine:placeholder _rest[0].text run data modify storage macroengine:placeholder _piece set from storage macroengine:placeholder _rest[0].text
execute unless data storage macroengine:placeholder _piece run function macroengine:core/internal/api/placeholder/_plain_resolve
execute if data storage macroengine:placeholder _piece run data modify storage macroengine:placeholder _parts append from storage macroengine:placeholder _piece
data remove storage macroengine:placeholder _rest[0]
function macroengine:core/internal/api/placeholder/_plain_loop
