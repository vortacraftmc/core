# ─────────────────────────────────────────────────────────────────
# macroengine:api/wand/register_cmd
# Binds a raw command to a wand (carrot_on_a_stick).
#
# INPUT (storage macroengine:input):
#   tag → custom_data tag name
#   cmd → raw command to run
#
# SECURITY: caller must hold macroengine.perm_level >= security.cmd_min_level
# (registering an arbitrary command onto a wand is gated the same as
# api/cb/run — the wand just fires it later, unattended by check_all,
# see core/internal/api/wand/call_cmd's own gate).
# ─────────────────────────────────────────────────────────────────

# Security gate — see core/internal/security/check_all.
# No-op (always passes) unless flags.experimental.strict_gating is on.
scoreboard players set #macroengine.gate_ok macroengine.tmp 0
execute store result score #macroengine.gate_ok macroengine.tmp run function macroengine:core/internal/security/check_all {required:"cmd_min_level"}
execute if score #macroengine.gate_ok macroengine.tmp matches 0 run return 0

execute unless data storage macroengine:engine wand_binds run data modify storage macroengine:engine wand_binds set value []
function macroengine:core/internal/api/wand/register_cmd_do with storage macroengine:input {}
