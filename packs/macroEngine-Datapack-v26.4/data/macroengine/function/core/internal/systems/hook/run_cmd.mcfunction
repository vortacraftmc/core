# macroengine:systems/hook/internal/run_cmd [MACRO]
# INPUT: $(cmd)
# @s = the triggering player
# No permission gate — runs $(cmd) unconditionally, debug tag only logs it.

execute if score #macroengine.log_level macroengine.log_level matches 4.. run tellraw @a[tag=macroengine.debug] ["",{"text":"[Hook] ","color":"aqua"},{"selector":"@s","color":"gold"},{"text":" cmd executed","color":"#555555"}]
$$(cmd)
