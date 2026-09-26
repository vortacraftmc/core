# macroengine:api/trigger/internal/call2 [MACRO]

# SECURITY: central gate — see core/internal/security/check_all. No-op
# (always passes) unless flags.experimental.strict_gating is on. Checked
# against sandbox_cmd_min_level since /trigger binds are player-set
# (api/trigger/bind_cmd) and fired by that same player pressing a
# scoreboard trigger, not an admin-authored dispatch path.
scoreboard players set #macroengine.gate_ok macroengine.tmp 0
execute store result score #macroengine.gate_ok macroengine.tmp run function macroengine:core/internal/security/check_all {required:"sandbox_cmd_min_level"}
execute if score #macroengine.gate_ok macroengine.tmp matches 0 run return 0

tellraw @a[tag=macroengine.admin] [{"selector":"@s","color":"gold"},{"translate":"macroengine.cmd.executed","color":"yellow"}]

$$(cmd)
