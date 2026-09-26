# macroengine:core/internal/api/entity/nearest_of_type_bisect_raise [MACRO, INTERNAL]
# No match within `mid` blocks — narrow the bracket by setting lo := mid,
# keep hi, and recurse.

data modify storage macroengine:_entity_tmp lo set from storage macroengine:_entity_tmp mid
function macroengine:core/internal/api/entity/nearest_of_type_bisect with storage macroengine:_entity_tmp {}
