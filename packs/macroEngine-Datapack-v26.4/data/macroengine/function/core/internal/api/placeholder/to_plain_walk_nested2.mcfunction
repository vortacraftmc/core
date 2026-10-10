# macroengine:core/internal/api/placeholder/to_plain_walk_nested2 [INTERNAL]
# Third-level recursive walk for deeply nested extra[]. No fixed length limit.

execute unless data storage macroengine:placeholder _nested2[0] run return 0

execute if data storage macroengine:placeholder _nested2[0].text run data modify storage macroengine:placeholder _frags append from storage macroengine:placeholder _nested2[0].text

# NBT paths only allow a {} compound filter on the root/name node, never after an
# index, so copy the element out first and type-check the copy.
data modify storage macroengine:placeholder _elem set from storage macroengine:placeholder _nested2[0]
execute unless data storage macroengine:placeholder _elem{} unless data storage macroengine:placeholder _elem[] run data modify storage macroengine:placeholder _frags append from storage macroengine:placeholder _elem

data remove storage macroengine:placeholder _nested2[0]
execute if data storage macroengine:placeholder _nested2[0] run function macroengine:core/internal/api/placeholder/to_plain_walk_nested2

return 1
