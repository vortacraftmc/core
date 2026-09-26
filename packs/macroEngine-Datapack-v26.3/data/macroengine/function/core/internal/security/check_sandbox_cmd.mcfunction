# macroengine:core/internal/security/check_sandbox_cmd [MACRO, INTERNAL]
# Validates $(cmd_name) against security.sandbox_allowlist as an exact
# compound-key membership check — same intent as how
# api/cmd/other/multi_cmd(_adv).mcfunction already validate
# multiCommands.type against security.multi_type_allowlist (truthy key
# present = allowed). Called exclusively by
# core/internal/security/check_all once perm_level has already cleared
# sandbox_cmd_min_level — do NOT call directly.
#
# Input (macro args via `with storage macroengine:_ca_tmp {}`):
#   $(cmd_name) — the command's own name (e.g. "say"), not the full
#                  argument string — see check_all.mcfunction's docstring
#                  for why this pack can't safely isolate a first word
#                  from arbitrary raw command text.
#
# OUTPUT: returns 1 if security.sandbox_allowlist.$(cmd_name) is present
#   and truthy, 0 otherwise. On denial, runs core/fallback/no_permission
#   (same as check_all's perm_level denial path) so callers get one
#   consistent "denied" experience regardless of which check failed.
# Uses the dynamic-path-segment macro pattern already proven in
# core/internal/api/gamerule/persist.mcfunction
# (gamerules.$(_gamerule_norm)), rather than a dynamic key inside a
# match-predicate compound, which is unverified syntax in this pack.

scoreboard players set $ca_allow_hit macroengine.tmp 0
$execute store result score $ca_allow_hit macroengine.tmp run data get storage macroengine:engine security.sandbox_allowlist.$(cmd_name)

execute if score $ca_allow_hit macroengine.tmp matches 1.. run return 1

function macroengine:core/fallback/no_permission
return 0
