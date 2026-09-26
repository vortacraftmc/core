# macroengine:backport/info
# Public API - shows backport status.
# On modern versions this is minimal.
# Overlays provide detailed legacy info.

tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.backport.active","color":"aqua"}]
tellraw @s ["",{"translate":"macroengine.backport.overlays","color":"gray"}]
