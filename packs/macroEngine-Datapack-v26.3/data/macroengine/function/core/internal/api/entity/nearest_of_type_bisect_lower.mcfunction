# macroengine:core/internal/api/entity/nearest_of_type_bisect_lower [MACRO, INTERNAL]
# A match was found within `mid` blocks — narrow the bracket by setting
# hi := mid, keep lo, and recurse.

data modify storage macroengine:_entity_tmp hi set from storage macroengine:_entity_tmp mid
function macroengine:core/internal/api/entity/nearest_of_type_bisect with storage macroengine:_entity_tmp {}
