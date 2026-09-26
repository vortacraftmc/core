# macroengine:experimental/hologram/remove
# Kills the nearest hologram entity to the caller (within 10 blocks).
#
# Usage:  function macroengine:experimental/hologram/remove
# Caller: macroengine.admin tag required

execute unless entity @s[tag=macroengine.admin] run return 0

execute as @e[tag=macroengine.experimental.hologram,sort=nearest,limit=1,distance=..10] run kill @s

tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.exp.hologram_removed","color":"yellow"}]
