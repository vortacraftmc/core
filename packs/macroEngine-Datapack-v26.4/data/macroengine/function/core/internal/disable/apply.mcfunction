# macroengine:core/internal/disable/apply
# The actual disable logic.
function macroengine:core/internal/load/cleanup
datapack disable "file/macroengine.zip"
datapack disable "file/macroengine"
datapack disable "file/macroEngine-Datapack-v26.4.zip"
datapack disable "file/macroEngine-Datapack-v26.4"
scoreboard players set #vortacraftmc.packs.macroengine.version macroengine.meta 0
tellraw @a ["",{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"macroengine disabled.","color":"red"}]
