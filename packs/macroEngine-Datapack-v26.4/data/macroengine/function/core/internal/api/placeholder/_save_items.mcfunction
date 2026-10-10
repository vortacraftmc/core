# macroengine:core/internal/api/placeholder/_save_items [INTERNAL]
# Mirrors the item/string forms made by _derive into macroengine:output placeholder.*
data modify storage macroengine:output placeholder.resolved set from storage macroengine:placeholder resolved
data modify storage macroengine:output placeholder.custom_name set from storage macroengine:placeholder custom_name
data modify storage macroengine:output placeholder.lore set from storage macroengine:placeholder lore
data modify storage macroengine:output placeholder.string set from storage macroengine:placeholder string
data modify storage macroengine:output placeholder.string_ok set from storage macroengine:placeholder string_ok
return 0
