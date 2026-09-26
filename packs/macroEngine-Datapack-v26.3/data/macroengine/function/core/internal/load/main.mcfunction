# macroengine:core/internal/load/main — load entry
# Initial load runs unblocked — must not stall server startup. Reload
# data-loss is only a soft warning here; force-reload
# (macroengine:core/internal/load/force) applies immediately, no confirmation
# gate (that gate system has been removed).

function macroengine:config

# Archive banner (score-controlled)
execute if score #vortacraftmc.archivedpacks.macroengine macroengine.meta matches 1 run tellraw @s {"translate":"macroengine.load.archived","color":"red"}

# Already loaded → data-loss prevention notice (NOT a hard gate; does not block)
execute if data storage macroengine:engine global{loaded:1b} if data storage macroengine:engine config{reload_warn:1b} run tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.load.reload_warn","color":"yellow"},{"translate":"macroengine.cmd.load_force","color":"aqua","underlined":true,"click_event":{"action":"run_command","command":"/function macroengine:core/internal/load/force"}}]

execute if data storage macroengine:engine global{loaded:1b} run return 0

schedule function macroengine:core/internal/load/all 2s
