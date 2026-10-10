# macroengine:core/internal/api/placeholder/to_plain_walk_array [INTERNAL]
# Recursively walks _walk (list of components or strings) and appends every
# visible plain text fragment onto _frags. No fixed length limit.
# Called only from to_plain (and from itself).

execute unless data storage macroengine:placeholder _walk[0] run return 0

execute if data storage macroengine:placeholder _walk[0].text run data modify storage macroengine:placeholder _frags append from storage macroengine:placeholder _walk[0].text

# NBT paths only allow a {} compound filter on the root/name node, never after an
# index, so copy the element out first and type-check the copy.
data modify storage macroengine:placeholder _elem set from storage macroengine:placeholder _walk[0]
execute unless data storage macroengine:placeholder _elem{} unless data storage macroengine:placeholder _elem[] run data modify storage macroengine:placeholder _frags append from storage macroengine:placeholder _elem

execute if data storage macroengine:placeholder _walk[0].extra[0] run data modify storage macroengine:placeholder _nested set from storage macroengine:placeholder _walk[0].extra
execute if data storage macroengine:placeholder _walk[0].extra[0] run function macroengine:core/internal/api/placeholder/to_plain_walk_nested

data remove storage macroengine:placeholder _walk[0]
execute if data storage macroengine:placeholder _walk[0] run function macroengine:core/internal/api/placeholder/to_plain_walk_array

return 1
