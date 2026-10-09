# ======================================================================================
# macroengine:systems/trim/scan
# ======================================================================================
#
# EXAMPLE PROCESSING MODULE for the macroengine:circuit / macroengine:overload
# custom trim added by this pack.
#
# macroEngine's enchantment/recipe/item_modifier registries ship a working
# *validation* layer (see input/validate/check) but never shipped any
# processing logic for the trim_pattern/trim_material registries also added
# here — this module is that missing piece, following the same
# read-input → validate → write-result convention as input/validate/check.
#
# Scans every armor slot on the executing entity and reports, per slot,
# whether it is wearing the "circuit" pattern in the "overload" material.
# Read-only — this function never modifies the scanned entity's equipment.
#
# CALL WITH:
#   execute as <entity> run function macroengine:systems/trim/scan
#
# OUTPUT (written to storage macroengine:trim result):
#   result.head/chest/legs/feet.present  — 1b if that slot has ANY trim
#   result.head/chest/legs/feet.matches  — 1b if that slot's trim is
#                                           exactly circuit + overload
#   result.any_matches                   — 1b if at least one slot matched
#
# Each slot with a matching trim also fires the
# "macroengine:trim_matched" hook event (see systems/hook) with the slot
# name in context, so other packs/functions can react without polling
# this function themselves.
# ======================================================================================

data remove storage macroengine:trim result
data modify storage macroengine:trim result.any_matches set value 0b

function macroengine:core/internal/systems/trim/_private/check_slot {slot: "head"}
function macroengine:core/internal/systems/trim/_private/check_slot {slot: "chest"}
function macroengine:core/internal/systems/trim/_private/check_slot {slot: "legs"}
function macroengine:core/internal/systems/trim/_private/check_slot {slot: "feet"}
