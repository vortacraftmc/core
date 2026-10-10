# macroengine:core/internal/api/placeholder/_lore_is_nl [INTERNAL]
# Sets #ph_nl to 1 when the text of _rest[0] is exactly a line break.
# `data modify ... set from` reports success only when the value changed, so
# success 0 means both strings were equal.
data modify storage macroengine:placeholder _cmp set value "\n"
execute store success score #ph_diff macroengine.tmp run data modify storage macroengine:placeholder _cmp set from storage macroengine:placeholder _rest[0].text
execute if score #ph_diff macroengine.tmp matches 0 run scoreboard players set #ph_nl macroengine.tmp 1
data remove storage macroengine:placeholder _cmp
