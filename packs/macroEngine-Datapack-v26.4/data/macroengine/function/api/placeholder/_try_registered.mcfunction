# macroengine:api/placeholder/_try_registered [INTERNAL]
data modify storage macroengine:text s set from storage macroengine:placeholder name
execute store result score #ph_ok macroengine.tmp run function macroengine:api/placeholder/_validate_name
execute if score #ph_ok macroengine.tmp matches 1 run function macroengine:api/placeholder/_lookup with storage macroengine:placeholder
