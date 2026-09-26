# macroengine:api/trigger/internal/call2 [MACRO]

# SECURITY: central gate

tellraw @a[tag=macroengine.admin] [{"selector":"@s","color":"gold"},{"translate":"macroengine.cmd.executed","color":"yellow"}]

$$(cmd)
