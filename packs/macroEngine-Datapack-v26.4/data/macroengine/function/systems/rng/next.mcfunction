# ─────────────────────────────────────────────────────────────────
# macroengine:systems/rng/next
# Advances the generator and writes the raw new state to
# macroengine:output result. Unbounded — use systems/rng/int when a
# value inside a range is wanted.
# ─────────────────────────────────────────────────────────────────

function macroengine:systems/rng/_core
execute store result storage macroengine:output result int 1 run scoreboard players get $rng_state macroengine.tmp
