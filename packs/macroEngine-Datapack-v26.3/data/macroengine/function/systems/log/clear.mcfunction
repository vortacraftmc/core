# macroengine:systems/log/clear
# Usage: /function macroengine:systems/log/clear
# Clears the log buffer.
execute unless entity @s[tag=macroengine.admin] run return 0
data remove storage macroengine:engine log_display
scoreboard players set #macroengine.log_count macroengine.tmp 0
tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.log.cleared","color":"gray"}]
