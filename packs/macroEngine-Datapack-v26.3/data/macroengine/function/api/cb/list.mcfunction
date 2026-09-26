# macroengine:api/cb/list
# ─────────────────────────────────────────────────────────────────
# Prints pending queue entries to the executor.
# Shows each queued command and its remaining ticks.
# ─────────────────────────────────────────────────────────────────


execute store result score #cb_queue_size macroengine.tmp run data get storage macroengine:engine cb_queue
execute if score #cb_queue_size macroengine.tmp matches 0 run tellraw @s [{"translate":"macroengine.prefix.cb","color":"#00AAAA","bold":true},{"translate":"macroengine.cb.queue_empty","color":"gray"}]
execute unless score #cb_queue_size macroengine.tmp matches 0 run tellraw @s [{"translate":"macroengine.prefix.cb","color":"#00AAAA","bold":true},{"translate":"macroengine.cb.queue_header","color":"#00AAAA","bold":true},{"score":{"name":"#cb_queue_size","objective":"macroengine.tmp"}},{"translate":"macroengine.cb.entries","color":"#00AAAA","bold":true}]
execute unless score #cb_queue_size macroengine.tmp matches 0 run tellraw @s {"nbt":"cb_queue","plain":true ,"storage":"macroengine:engine","interpret":false}
