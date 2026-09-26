# macroengine:systems/hook/unbind_all
# Clears all hook binds.

data modify storage macroengine:engine hook_binds set value []

# # tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.hook_unbind_all","color":"aqua"},{"translate":"macroengine.debug.hooks_cleared","color":"yellow"}]
