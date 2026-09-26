# ─────────────────────────────────────────────────────────────────
# macroengine:api/cmd/other/multi_cmd/utils/clear_queue
# Clear the queue
# ─────────────────────────────────────────────────────────────────

data remove storage macroengine:engine _mcmd_queue
# # tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.multi_cmd_utils_clear","color":"aqua"},{"translate":"macroengine.debug.queue_cleared","color":"yellow"}]
