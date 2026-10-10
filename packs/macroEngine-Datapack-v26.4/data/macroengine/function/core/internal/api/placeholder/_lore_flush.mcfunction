# macroengine:core/internal/api/placeholder/_lore_flush [INTERNAL]
# Appends _line to lore_live as one line and starts a new one. Each line gets an empty
# root with italic:false, so every part of it inherits "not italic" (vanilla lore is
# italic by default) and an empty line is simply the bare root.
data modify storage macroengine:placeholder _line prepend value {text:"",italic:false}
data modify storage macroengine:placeholder lore_live append from storage macroengine:placeholder _line
data modify storage macroengine:placeholder _line set value []
