# macroengine:core/internal/api/placeholder/_plain_resolve [INTERNAL]
# Resolves _rest[0] on the scratch item and leaves its text in _piece (unset when it has none).
# The item stores the resolved name in one of two shapes, and both must be read:
#   - a compound with `text` when the result carries a style (a selector resolves with
#     click/hover events), and
#   - a bare string when the result is unstyled plain text (a `plain` NBT value such as
#     Health, a score) - there is no `.text` path on a string, so reading only `.text`
#     silently dropped those parts from `string`.
# Anything else (translate, a list ...) is skipped, as documented in api/placeholder/parse.
data modify storage macroengine:placeholder _src set from storage macroengine:placeholder _rest[0]
item modify entity @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1] container.0 macroengine:placeholder/name
data remove storage macroengine:placeholder _res
data modify storage macroengine:placeholder _res set from entity @e[type=minecraft:chest_minecart,tag=macroengine.ph_scratch,distance=..2,limit=1] Items[{Slot:0b}].components."minecraft:custom_name"
execute if data storage macroengine:placeholder _res{} if data storage macroengine:placeholder _res.text run data modify storage macroengine:placeholder _piece set from storage macroengine:placeholder _res.text
execute unless data storage macroengine:placeholder _res{} unless data storage macroengine:placeholder _res[0] run data modify storage macroengine:placeholder _piece set from storage macroengine:placeholder _res
data remove storage macroengine:placeholder _res
