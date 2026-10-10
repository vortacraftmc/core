# macroengine:core/internal/api/placeholder/_derive [INTERNAL]
# Builds the item-ready forms of `out` in macroengine:placeholder:
#   string       the component list written out as an SNBT string
#   custom_name  one component for `custom_name=`: out with italic:false on the root
#                (vanilla draws custom names and lore in italics unless told not to)
#   lore         list of lines for `lore=`: out cut at every %nl% (a {text:"\n"}
#                component), every line one component array with italic:false on its root
# A root that already sets italic keeps it.
data modify storage macroengine:placeholder string set string storage macroengine:placeholder out

data modify storage macroengine:placeholder custom_name set from storage macroengine:placeholder out
execute unless data storage macroengine:placeholder custom_name[0] run data modify storage macroengine:placeholder custom_name set value [{text:""}]
execute unless data storage macroengine:placeholder custom_name[0].italic run data modify storage macroengine:placeholder custom_name[0].italic set value false

data modify storage macroengine:placeholder lore set value []
data modify storage macroengine:placeholder _line set value []
data modify storage macroengine:placeholder _rest set from storage macroengine:placeholder out
function macroengine:core/internal/api/placeholder/_lore_loop
data remove storage macroengine:placeholder _line
data remove storage macroengine:placeholder _rest
