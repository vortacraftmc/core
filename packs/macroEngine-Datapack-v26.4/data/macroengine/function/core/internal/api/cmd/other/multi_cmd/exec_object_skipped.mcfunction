# ─────────────────────────────────────────────────────────────────
# macroengine:core/internal/api/cmd/other/multi_cmd/exec_object_skipped
# The entry's condition did not pass, so nothing ran. Called via
# `return run` from exec_object; counting the skip here lets `profile:1b`
# reports tell "did not run" apart from "ran and did nothing".
# ─────────────────────────────────────────────────────────────────

execute if data storage macroengine:engine _mcmd_options{profile:1b} run scoreboard players add $mcmd_skipped macroengine.tmp 1
