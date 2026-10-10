# macroengine:core/internal/api/placeholder/_plain [INTERNAL]
# Flattens `out` into the plain string `string`. Text parts are taken as they are; every
# other part (selector, score, NBT ...) is resolved on the scratch item and its text read
# back. Joining uses core/internal/text/concat, which refuses a part holding a double quote
# or backslash: then string stays "" and string_ok becomes 0b rather than being wrong.
data modify storage macroengine:placeholder _parts set value []
data modify storage macroengine:placeholder _rest set from storage macroengine:placeholder out
function macroengine:core/internal/api/placeholder/_plain_loop
data modify storage macroengine:text list set from storage macroengine:placeholder _parts
execute store result score #ph_ok macroengine.tmp run function macroengine:core/internal/text/concat
execute if score #ph_ok macroengine.tmp matches 1 run data modify storage macroengine:placeholder string set from storage macroengine:text out
execute if score #ph_ok macroengine.tmp matches 0 run data modify storage macroengine:placeholder string_ok set value 0b
function macroengine:core/internal/text/reset
data remove storage macroengine:placeholder _parts
data remove storage macroengine:placeholder _piece
