# ─────────────────────────────────────────────────────────────────
# macroengine:core/internal/api/cmd/other/multi_cmd/selftest_assert [MACRO]
# INPUT: $(name)
# ─────────────────────────────────────────────────────────────────

execute store success score $selftest_actual macroengine.tmp if data storage macroengine:engine _selftest_ran

execute if score $selftest_actual macroengine.tmp = $selftest_expected macroengine.tmp run scoreboard players add $selftest_pass macroengine.tmp 1
execute unless score $selftest_actual macroengine.tmp = $selftest_expected macroengine.tmp run scoreboard players add $selftest_fail macroengine.tmp 1

$execute unless score $selftest_actual macroengine.tmp = $selftest_expected macroengine.tmp run tellraw @s [{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"FAIL ","color":"red","bold":true},{"text":"$(name)","color":"white"},{"text":" — expected ","color":"gray"},{"score":{"name":"$selftest_expected","objective":"macroengine.tmp"},"color":"aqua"},{"text":", got ","color":"gray"},{"score":{"name":"$selftest_actual","objective":"macroengine.tmp"},"color":"red"}]
