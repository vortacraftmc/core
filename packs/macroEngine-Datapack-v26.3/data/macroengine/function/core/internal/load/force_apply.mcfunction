# macroengine:core/internal/load/force_apply
# Actually performs the force re-init: drops the loaded flag and
# re-runs the full init pipeline, discarding any live engine state
# that macroengine:core/internal/load/all's "unless data" guards would otherwise preserve.
#
# UNSUPPORTED PACK: force-reload is not a bypass of the unsupported gate —
# it must be re-checked here too, or /function .../load/force would let
# anyone skip core/internal/load/main's block entirely.
execute unless function macroengine:core/internal/load/unsupported_gate run return 0

data remove storage macroengine:engine global.loaded
tellraw @a ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.load.force","color":"yellow"}]
function macroengine:core/internal/load/all
