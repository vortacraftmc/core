# macro: $(cmd)     as player
# Runs with the permission level datapack functions get (function-permission-level, default 2),
# not the player's own. cmd must come from menu code / definitions, never from player input.
# vc-gate: sink guard, disabled unless guikit:gate/v5 state is active
execute unless data storage guikit:gate/v5 {state:"active"} run return fail
$execute as @s at @s run $(cmd)
