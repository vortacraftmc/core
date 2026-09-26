# macroengine:systems/hook/internal/run_cmd [MACRO]
# INPUT: $(cmd)
# @s = the triggering player

# SECURITY: central gate

execute if score #macroengine.log_level macroengine.log_level matches 4.. run tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.debug.hook_prefix","color":"aqua"},{"selector":"@s","color":"gold"},{"translate":"macroengine.debug.cmd_exec","color":"#555555"}]
$$(cmd)
