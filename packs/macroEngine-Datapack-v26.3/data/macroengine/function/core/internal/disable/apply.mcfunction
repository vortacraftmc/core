# macroengine:core/internal/disable/apply
# The actual disable logic.
function macroengine:core/internal/load/cleanup
datapack disable "file/macroengine.zip"
datapack disable "file/macroengine"
scoreboard players set #vortacraftmc.packs.macroengine.version macroengine.meta 0
tellraw @a ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.load.disabled","color":"red"}]
