# macroengine:core/state/get_score
# Prints the calling player's current state score.
# Usage: /function macroengine:core/state/get_score
tellraw @s ["",{"translate":"macroengine.state.prefix","color":"aqua"},{"translate":"macroengine.state.current","color":"gray"},{"score":{"name":"@s","objective":"macroengine.state"},"color":"white","bold":true}]
