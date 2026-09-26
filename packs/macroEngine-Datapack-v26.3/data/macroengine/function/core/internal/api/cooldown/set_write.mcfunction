# macroengine:core/internal/api/cooldown/set_write [MACRO, INTERNAL]
# Writes the computed expiry tick into the engine-wide cooldown registry,
# keyed by player UUID then normalized cooldown name. Called exclusively
# by macroengine:api/cooldown/set — do NOT call directly.
#
# Input (macro args via `with storage macroengine:_cooldown_tmp {}`):
#   $(_uuid)   — player UUID string
#   $(_name)   — normalized cooldown name string
#   $(_expiry) — absolute gametime tick the cooldown ends

$data modify storage macroengine:engine cooldowns.$(_uuid).$(_name) set value $(_expiry)
