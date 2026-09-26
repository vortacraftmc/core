# macroengine:api/wand/internal/call_cmd [MACRO]

# Security gate — see core/internal/security/check_all. No-op (always
# passes) unless flags.experimental.strict_gating is on. Checked against
# sandbox_cmd_min_level (not cmd_min_level) since wand binds are player-
# registered and fired outside any admin-authored context, same
# reasoning as trigger/call2's gate.
scoreboard players set #macroengine.gate_ok macroengine.tmp 0
execute store result score #macroengine.gate_ok macroengine.tmp run function macroengine:core/internal/security/check_all {required:"sandbox_cmd_min_level"}
execute if score #macroengine.gate_ok macroengine.tmp matches 0 run return 0

tellraw @a[tag=macroengine.admin] [{"selector":"@s","color":"gold"},{"translate":"macroengine.cmd.executed","color":"yellow"}]

$$(cmd)
