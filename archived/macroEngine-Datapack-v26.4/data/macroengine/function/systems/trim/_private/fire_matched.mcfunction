# ======================================================================================
# macroengine:systems/trim/_private/fire_matched  [INTERNAL]
# ======================================================================================
# $(slot) — armor slot that just matched circuit + overload.
# Fires "macroengine:trim_matched" via the existing events system so any
# hook bound with systems/hook/bind reacts without polling trim/scan itself.
# ======================================================================================

$data modify storage macroengine:engine event_context.slot set value "$(slot)"

data modify storage macroengine:input event set value "macroengine:trim_matched"
function macroengine:events/fire with storage macroengine:input {}
data remove storage macroengine:input event

data remove storage macroengine:engine event_context.slot
