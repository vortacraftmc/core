# macroengine:api/wand/unregister_all — Clears all wand binds.
data modify storage macroengine:engine wand_binds set value []
# # tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.wand_unregister_all","color":"aqua"},{"translate":"macroengine.debug.wand_cleared","color":"yellow"}]
