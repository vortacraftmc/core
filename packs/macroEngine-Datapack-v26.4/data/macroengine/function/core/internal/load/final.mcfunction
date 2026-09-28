data modify storage macroengine:engine global.version set value "v26.4-snapshot-1"
scoreboard players set #vortacraftmc.packs.macroengine.version macroengine.meta 264
function #macroengine:init

tellraw @a ["",{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"macroEngine v26.4-snapshot-1 loaded.","color":"green"}]
