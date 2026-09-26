# macroengine:core/queue/clear
# Discards all pending work_queue items immediately.
# No macro input required.
#
# Usage:
#   function macroengine:core/queue/clear

data modify storage macroengine:engine work_queue set value []
# # tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.queue_clear","color":"aqua"},{"translate":"macroengine.debug.work_queue_empty","color":"#555555"}]
