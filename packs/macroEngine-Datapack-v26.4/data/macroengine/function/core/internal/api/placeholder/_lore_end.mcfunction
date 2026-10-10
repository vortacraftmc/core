# macroengine:core/internal/api/placeholder/_lore_end [INTERNAL]
# End of input: keep the last line only when it has content (a trailing %nl% adds no empty line).
execute if data storage macroengine:placeholder _line[0] run function macroengine:core/internal/api/placeholder/_lore_flush
