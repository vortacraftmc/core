# ─────────────────────────────────────────────────────────────────
# macroengine:core/internal/security/check_all [MACRO]
#
# THE central permission gate for cmd/, cb/, and raw wand/trigger
# dispatch. This is the function `admin_min_level`, `cmd_min_level`,
# and `sandbox_cmd_min_level` have been documented as enforcing
# (via "(check_all)" / "SECURITY: caller must hold...") since v26.3,
# but the function never existed — nothing actually read
# macroengine.perm_level anywhere in the pack. This file closes that gap.
#
# Gated behind flags.experimental.strict_gating (systems/flag/experimental).
# Flag OFF -> always return 1 (pass), i.e. identical to current
# (unenforced) behavior. This is a real kill switch: if strict_gating
# causes problems again, disable the flag and every caller of this
# function silently no-ops back to "allow everyone", no code changes
# needed. Flag ON -> live perm_level enforcement below.
#
# Run `as <player>` — @s IS the caller. Matches the pack's existing
# convention (api/cmd/*, api/cb/* already assume @s is the executor).
#
# INPUT (macro):
#   $(required)  -> REQUIRED. Threshold key in `security` storage to
#                    check against: "cmd_min_level" |
#                    "sandbox_cmd_min_level" | "admin_min_level"
#   $(cmd_name)  -> OPTIONAL. The command's own name only (e.g. "say",
#                    "tp" — NOT the full argument string; this pack has
#                    no substring/split helper that reliably isolates a
#                    command's first word from arbitrary raw text — see
#                    core/internal/string/util/split.mcfunction's own
#                    header, which documents that split is currently
#                    broken). Callers that know the command name ahead
#                    of time (e.g. a fixed cb/wand/trigger binding) can
#                    supply it directly. When $(required) is
#                    "sandbox_cmd_min_level" and security.sandbox_allowlist
#                    is non-empty, $(cmd_name) is looked up as an exact
#                    key in that allowlist (same compound-membership
#                    pattern as security.multi_type_allowlist). Omit
#                    $(cmd_name) (or leave sandbox_allowlist empty, the
#                    default) to skip this check entirely.
#
# admin_can_override (security storage, default 0b as documented in
# loader/storages.mcfunction): while 0b, the macroengine.admin tag does
# NOT bypass these checks — admins are subject to the same
# perm_level / allowlist rules as anyone else. Set admin_can_override
# to 1b to restore the old "admin tag always passes" shortcut.
#
# sandbox_allowlist (security storage, default {} = empty compound, per
# loader/storages.mcfunction's "BREAKING CHANGE: ... is now a compound
# {} (was list []). Empty compound {} = all sandbox commands blocked."):
# when checking "sandbox_cmd_min_level" with a $(cmd_name) supplied,
# $(cmd_name) must exist as a truthy key in the allowlist (e.g.
# {"say":1b,"tp":1b}) or the call is denied regardless of perm_level —
# including when the allowlist is empty, matching that documented
# fail-closed default. Omit $(cmd_name) entirely to skip this check and
# rely on perm_level alone (e.g. for callers that can't identify a
# command name up front).
#
# OUTPUT: returns 1 if allowed, 0 if denied.
#   On denial: runs core/fallback/no_permission as the same @s (tellraw +
#   log), matching no_permission's own docstring ("perm_level below
#   required threshold").
# ─────────────────────────────────────────────────────────────────

# Flag OFF -> unconditional pass (backward-compatible / kill-switch default)
execute unless data storage macroengine:engine flags.experimental{strict_gating:1b} run return 1

# admin tag bypasses checks only while admin_can_override is explicitly
# on — the documented default (0b) means admins are checked like anyone
# else. `unless data ... {admin_can_override:0b}` also covers a missing
# key the same way `execute unless data storage ... security.admin_can_override`
# would, without a second lookup.
execute if entity @s[tag=macroengine.admin] unless data storage macroengine:engine security{admin_can_override:0b} run return 1

scoreboard players set $ca_required macroengine.tmp -1
$execute store result score $ca_required macroengine.tmp run data get storage macroengine:engine security.$(required)

execute if score @s macroengine.perm_level < $ca_required macroengine.tmp run function macroengine:core/fallback/no_permission
execute if score @s macroengine.perm_level < $ca_required macroengine.tmp run return 0

# perm_level cleared the threshold. If this is a sandbox check with a
# command name supplied and an allowlist configured, that name must
# also be an allowlisted key. Macro args aren't directly comparable
# with `execute if` (that's for entity/score/data/etc, not string
# literals) — write required/cmd_name into storage first, same pattern
# used throughout this pack for storage-driven comparisons.
$data modify storage macroengine:_ca_tmp required set value "$(required)"
$data modify storage macroengine:_ca_tmp cmd_name set value "$(cmd_name)"
execute if data storage macroengine:_ca_tmp{required:"sandbox_cmd_min_level"} unless data storage macroengine:_ca_tmp{cmd_name:""} run return run function macroengine:core/internal/security/check_sandbox_cmd with storage macroengine:_ca_tmp
data remove storage macroengine:_ca_tmp required
data remove storage macroengine:_ca_tmp cmd_name

return 1
