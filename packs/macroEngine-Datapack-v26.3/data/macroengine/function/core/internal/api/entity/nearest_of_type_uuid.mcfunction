# macroengine:core/internal/api/entity/nearest_of_type_uuid [INTERNAL]
# Executed `as` the matched entity (see api/entity/nearest_of_type).
# Delegates to the pack's existing UUID-to-string system
# (macroengine:systems/uuid/from_entity) and copies its result into
# macroengine:output uuid.

function macroengine:systems/uuid/from_entity
data modify storage macroengine:output uuid set from storage macroengine:input value
