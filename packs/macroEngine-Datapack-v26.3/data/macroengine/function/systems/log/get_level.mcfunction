# macroengine:systems/log/get_level
# Usage: /function macroengine:systems/log/get_level
# Shows the current log level.
tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.log.level","color":"gray"},{"score":{"name":"#macroengine.log_level","objective":"macroengine.log_level"},"color":"white","bold":true},{"translate":"macroengine.log.level_help","color":"#555555"}]
