# macroengine:api/placeholder/_validate_name [INTERNAL]
# INPUT macroengine:text s. RETURN 1 when s holds no quote, backslash or any
# character from the deny_name table, else 0. Always resets the text buffers.
execute store result score #ph_ok macroengine.tmp run function macroengine:core/internal/text/safe
execute if score #ph_ok macroengine.tmp matches 0 run function macroengine:core/internal/text/reset
execute if score #ph_ok macroengine.tmp matches 0 run return 0
data modify storage macroengine:text tbl set value "deny_name"
execute store result score #ph_bad macroengine.tmp run function macroengine:core/internal/text/scan_deny
function macroengine:core/internal/text/reset
execute if score #ph_bad macroengine.tmp matches 1 run return 0
return 1
