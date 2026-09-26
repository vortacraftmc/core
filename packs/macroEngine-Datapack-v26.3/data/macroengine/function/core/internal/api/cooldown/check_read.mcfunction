# macroengine:core/internal/api/cooldown/check_read [MACRO, INTERNAL]
# Reads the stored expiry tick for a player UUID + cooldown name out of
# the engine-wide registry into a scoreboard score for comparison. Called
# exclusively by macroengine:api/cooldown/check — do NOT call directly.
#
# Input (macro args via `with storage macroengine:_cooldown_tmp {}`):
#   $(_uuid) — player UUID string
#   $(_name) — normalized cooldown name string

$execute store result score #macroengine_cooldown_expiry macroengine.tmp run data get storage macroengine:engine cooldowns.$(_uuid).$(_name)
