# macroEngine — resource pack requirement check
# @s = player
title @s times 5 60 10
title @s title {"translate":"macroengine.rp.missing.title","color":"red","bold":true}
title @s subtitle {"translate":"macroengine.rp.missing","color":"gray"}
tellraw @s ["",{"text":"\uE000","color":"#00AAAA"},{"text":" ","color":"#00AAAA"},{"translate":"macroengine.rp.missing","color":"red","bold":true}]
playsound macroengine:ui.error master @s ~ ~ ~ 0.8 1
tag @s add macroengine.rp_warned
