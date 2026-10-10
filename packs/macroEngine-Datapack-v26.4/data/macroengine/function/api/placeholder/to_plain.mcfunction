# macroengine:api/placeholder/to_plain
# Public entry: resolve any text component to a plain string in storage.
# No tellraw. Output is always a string type.
#
# Input:  storage macroengine:placeholder in.component
# Output: storage macroengine:placeholder out.string
#         storage macroengine:output      placeholder.string
# Return: 1 on success, 0 when in.component is missing
#
# Usage:
#   data modify storage macroengine:placeholder in.component set value {selector:"@s"}
#   function macroengine:api/placeholder/to_plain

return run function macroengine:core/internal/api/placeholder/to_plain
