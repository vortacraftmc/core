# macroengine:api/toggle/show
# Prints a clickable module enable/disable menu.
#
# Usage:  function macroengine:api/toggle/show
# Caller: macroengine.admin tag required
#
# Each button runs:
#   /function macroengine:api/toggle/<Module>/<State>
#   where <State> is "true" (enable) or "false" (disable).
#
# Supported modules: hook, interaction, perm, wand, geo, cb
#
# BACKPORT NOTE (1.21.2): the original (26.x) opened this as a native
# `dialog show` screen with a free-text "Module Name" field and a boolean
# toggle, submitted via minecraft:dynamic/run_command templating. The
# dialog system does not exist in 1.21.2 (added in 1.21.6, pack format 80),
# and free-text input has no chat-command equivalent. Reimplemented as a
# fixed clickable menu — one Enable/Disable button pair per known module —
# which is functionally equivalent since the module list is fixed anyway.

execute unless entity @s[tag=macroengine.admin] run return 0

tellraw @s ["",{"translate":"macroengine.ui.eq_pre","color":"dark_gray"},{"translate":"macroengine.module.toggles_title","color":"aqua","bold":true},{"translate":"macroengine.ui.eq_post","color":"dark_gray"}]
tellraw @s ["",{"translate":"macroengine.mod.hook_pad","color":"white"},{"translate":"macroengine.ui.on_btn","color":"green","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/hook/true"}},{"translate":"macroengine.ui.off_btn","color":"red","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/hook/false"}}]
tellraw @s ["",{"translate":"macroengine.mod.interaction","color":"white"},{"translate":"macroengine.ui.on_btn","color":"green","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/interaction/true"}},{"translate":"macroengine.ui.off_btn","color":"red","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/interaction/false"}}]
tellraw @s ["",{"translate":"macroengine.mod.perm_pad","color":"white"},{"translate":"macroengine.ui.on_btn","color":"green","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/perm/true"}},{"translate":"macroengine.ui.off_btn","color":"red","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/perm/false"}}]
tellraw @s ["",{"translate":"macroengine.mod.wand_pad","color":"white"},{"translate":"macroengine.ui.on_btn","color":"green","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/wand/true"}},{"translate":"macroengine.ui.off_btn","color":"red","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/wand/false"}}]
tellraw @s ["",{"translate":"macroengine.mod.geo_pad","color":"white"},{"translate":"macroengine.ui.on_btn","color":"green","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/geo/true"}},{"translate":"macroengine.ui.off_btn","color":"red","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/geo/false"}}]
tellraw @s ["",{"translate":"macroengine.mod.cb_pad","color":"white"},{"translate":"macroengine.ui.on_btn","color":"green","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/cb/true"}},{"translate":"macroengine.ui.off_btn","color":"red","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/cb/false"}}]
tellraw @s ["",{"translate":"macroengine.mod.exp_flags_link","color":"yellow","italic":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/experimental/show"},"hover_event":{"action":"show_text","value":"Open the experimental feature-flag menu"}}]
