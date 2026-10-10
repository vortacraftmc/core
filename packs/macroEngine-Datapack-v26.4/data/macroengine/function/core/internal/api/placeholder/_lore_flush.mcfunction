# macroengine:core/internal/api/placeholder/_lore_flush [INTERNAL]
# Appends _line to lore as one line and starts a new one. An empty line becomes an empty component.
execute unless data storage macroengine:placeholder _line[0] run data modify storage macroengine:placeholder _line set value [{text:""}]
execute unless data storage macroengine:placeholder _line[0].italic run data modify storage macroengine:placeholder _line[0].italic set value false
data modify storage macroengine:placeholder lore append from storage macroengine:placeholder _line
data modify storage macroengine:placeholder _line set value []
