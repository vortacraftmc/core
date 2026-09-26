# macroEngine resource pack requirement check
# Runs as the joining player. If translate key is not resolved (RP missing),
# the fallback text is shown and the player is warned.

# Mark that we attempted check
tag @s add macroengine.rp_checked

# Actionbar warning (shows key name if RP missing, "OK" if present — but we use a dedicated title)
title @s actionbar {"translate":"macroengine.rp.missing.actionbar","color":"red","bold":true}

# Tellraw with the missing message (always show until they have RP — client resolves translate)
tellraw @s ["",{"text":"\uE000","color":"#00AAAA"},{"text":" ","color":"#00AAAA"},{"translate":"macroengine.rp.missing","color":"red"}]
