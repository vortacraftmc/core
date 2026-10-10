# macroengine:core/internal/api/placeholder/to_plain_walk_nested2 [INTERNAL]
# Third-level recursive walk for deeply nested extra[]. No fixed length limit.

execute unless data storage macroengine:placeholder _nested2[0] run return 0

execute if data storage macroengine:placeholder _nested2[0].text run data modify storage macroengine:placeholder _frags append from storage macroengine:placeholder _nested2[0].text

execute if data storage macroengine:placeholder _nested2[0] unless data storage macroengine:placeholder _nested2[0]{} unless data storage macroengine:placeholder _nested2[0][] run data modify storage macroengine:placeholder _frags append from storage macroengine:placeholder _nested2[0]

data remove storage macroengine:placeholder _nested2[0]
execute if data storage macroengine:placeholder _nested2[0] run function macroengine:core/internal/api/placeholder/to_plain_walk_nested2

return 1
