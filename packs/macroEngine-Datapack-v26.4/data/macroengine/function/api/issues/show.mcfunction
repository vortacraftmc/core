# Render the issue list from storage.
#
# Each line is guarded by `if data`, so a short list simply stops and a long
# one is cut off at the number of slots below rather than erroring. The count
# is whatever packd managed to fit in one RCON command; the header says how
# many were included, so a truncated list is never silently mistaken for a
# complete one.
#
# Clicking a line opens the issue in the browser. Hovering shows the author,
# the last update, the labels and the first line of the body.

execute if data storage macroengine:issues issues[0] run function macroengine:core/internal/issues/entry with storage macroengine:issues issues[0]
execute if data storage macroengine:issues issues[1] run function macroengine:core/internal/issues/entry with storage macroengine:issues issues[1]
execute if data storage macroengine:issues issues[2] run function macroengine:core/internal/issues/entry with storage macroengine:issues issues[2]
execute if data storage macroengine:issues issues[3] run function macroengine:core/internal/issues/entry with storage macroengine:issues issues[3]
execute if data storage macroengine:issues issues[4] run function macroengine:core/internal/issues/entry with storage macroengine:issues issues[4]
execute if data storage macroengine:issues issues[5] run function macroengine:core/internal/issues/entry with storage macroengine:issues issues[5]
execute if data storage macroengine:issues issues[6] run function macroengine:core/internal/issues/entry with storage macroengine:issues issues[6]
execute if data storage macroengine:issues issues[7] run function macroengine:core/internal/issues/entry with storage macroengine:issues issues[7]
execute if data storage macroengine:issues issues[8] run function macroengine:core/internal/issues/entry with storage macroengine:issues issues[8]
execute if data storage macroengine:issues issues[9] run function macroengine:core/internal/issues/entry with storage macroengine:issues issues[9]
execute if data storage macroengine:issues issues[10] run function macroengine:core/internal/issues/entry with storage macroengine:issues issues[10]
execute if data storage macroengine:issues issues[11] run function macroengine:core/internal/issues/entry with storage macroengine:issues issues[11]
execute if data storage macroengine:issues issues[12] run function macroengine:core/internal/issues/entry with storage macroengine:issues issues[12]
execute if data storage macroengine:issues issues[13] run function macroengine:core/internal/issues/entry with storage macroengine:issues issues[13]
execute if data storage macroengine:issues issues[14] run function macroengine:core/internal/issues/entry with storage macroengine:issues issues[14]

tellraw @a [{"text":" ","color":"dark_gray"},{"text":"hover a line for details, click to open it","color":"dark_gray","italic":true}]
