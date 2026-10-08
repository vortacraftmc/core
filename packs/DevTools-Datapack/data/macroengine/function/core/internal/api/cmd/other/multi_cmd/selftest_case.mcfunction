# ─────────────────────────────────────────────────────────────────
# macroengine:core/internal/api/cmd/other/multi_cmd/selftest_case [MACRO]
# Runs ONE queue entry and checks whether it actually ran.
#
# INPUT: $(name)   — label used when the case fails
#        $(entry)  — the queue entry under test
#        $(expect) — 1 if the entry should run, 0 if it should be skipped
#
# The entry's command sets _selftest_ran; its presence afterwards is the
# only evidence consulted, so this measures the real gate rather than
# restating what the code claims to do.
# ─────────────────────────────────────────────────────────────────

data remove storage macroengine:engine _selftest_ran
$scoreboard players set $selftest_expected macroengine.tmp $(expect)

$function macroengine:api/cmd/other/multi_cmd {commands:[$(entry)]}

$function macroengine:core/internal/api/cmd/other/multi_cmd/selftest_assert {name:"$(name)"}
