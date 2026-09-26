# macroengine:api/trigger/bind_cmd [MACRO]
# Binds a raw command to a scoreboard trigger value.
#
# SECURITY: caller must hold macroengine.perm_level >= security.cmd_min_level
# (same reasoning as api/wand/register_cmd — this stores a command that
# will later run unattended via api/trigger/call2's own gate).

# Security gate — see core/internal/security/check_all.
# No-op (always passes) unless flags.experimental.strict_gating is on.
scoreboard players set #macroengine.gate_ok macroengine.tmp 0
execute store result score #macroengine.gate_ok macroengine.tmp run function macroengine:core/internal/security/check_all {required:"cmd_min_level"}
execute if score #macroengine.gate_ok macroengine.tmp matches 0 run return 0

execute unless data storage macroengine:engine trigger_binds run data modify storage macroengine:engine trigger_binds set value []

$data modify storage macroengine:engine trigger_binds append value {value:$(value), cmd:"$(cmd)"}
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.trigger_bind_cmd","color":"aqua"},{"text":"✔ ","color":"green"},{"text":"$(value)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(cmd)","color":"aqua"}]
