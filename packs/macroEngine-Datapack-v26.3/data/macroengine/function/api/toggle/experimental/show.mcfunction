# macroengine:api/toggle/experimental/show
# Prints a clickable experimental-flag enable/disable menu.
#
# Usage:  function macroengine:api/toggle/experimental/show
# Caller: macroengine.admin tag required
#
# Each button runs:
#   /function macroengine:api/toggle/experimental/<true|false> {flag:"<name>"}
#
# Flags:
#   strict_gating   — enables core/internal/security/check_all enforcement
#                      (cmd_min_level / sandbox_cmd_min_level / admin_min_level,
#                      plus security.admin_can_override and
#                      security.sandbox_allowlist — the wand/trigger raw-
#                      command dispatch paths and their register/bind
#                      steps are now gated too, not just cmd/ and cb/).
#                      Turn this OFF immediately if permission checks start
#                      blocking things that should work — every threshold
#                      defaults to 0 (everyone passes) so leaving it on is
#                      safe out of the box. Ships ON by default as of this
#                      build (see config.mcfunction); fresh installs get
#                      enforcement live once you raise a *_min_level above 0,
#                      existing worlds that already wrote a value here keep it.
#   hologram        — experimental/hologram/* (floating text display entities)
#   particle_trail  — experimental/particle_trail/* (player movement trails)
#   crafting_ui     — experimental/crafting_ui/* (custom crafting menu)
#   waypoint        — experimental/waypoint/* (set/track/compass waypoints)
#   combat_tag      — experimental/combat_tag/* (temporary PvP-tag on hit)
#   scoreboard_hud  — experimental/scoreboard_hud/* (sidebar HUD toggle)
#
# BACKPORT NOTE (1.21.2): same constraint as api/toggle/show.mcfunction —
# no `dialog show` (added 1.21.6 / pack format 80) available here, so this
# is a fixed clickable tellraw menu, not a native dialog screen.

execute unless entity @s[tag=macroengine.admin] run return 0

tellraw @s ["",{"translate":"macroengine.ui.eq_pre","color":"dark_gray"},{"translate":"macroengine.exp.flags_title","color":"aqua","bold":true},{"translate":"macroengine.ui.eq_post","color":"dark_gray"}]
tellraw @s ["",{"translate":"macroengine.flag.strict_gating","color":"white"},{"translate":"macroengine.ui.on_btn","color":"green","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/experimental/true {flag:\"strict_gating\"}"}},{"translate":"macroengine.ui.off_btn","color":"red","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/experimental/false {flag:\"strict_gating\"}"}}]
tellraw @s ["",{"translate":"macroengine.flag.hologram","color":"white"},{"translate":"macroengine.ui.on_btn","color":"green","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/experimental/true {flag:\"hologram\"}"}},{"translate":"macroengine.ui.off_btn","color":"red","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/experimental/false {flag:\"hologram\"}"}}]
tellraw @s ["",{"translate":"macroengine.flag.particle_trail","color":"white"},{"translate":"macroengine.ui.on_btn","color":"green","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/experimental/true {flag:\"particle_trail\"}"}},{"translate":"macroengine.ui.off_btn","color":"red","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/experimental/false {flag:\"particle_trail\"}"}}]
tellraw @s ["",{"translate":"macroengine.flag.crafting_ui","color":"white"},{"translate":"macroengine.ui.on_btn","color":"green","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/experimental/true {flag:\"crafting_ui\"}"}},{"translate":"macroengine.ui.off_btn","color":"red","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/experimental/false {flag:\"crafting_ui\"}"}}]
tellraw @s ["",{"translate":"macroengine.flag.waypoint","color":"white"},{"translate":"macroengine.ui.on_btn","color":"green","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/experimental/true {flag:\"waypoint\"}"}},{"translate":"macroengine.ui.off_btn","color":"red","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/experimental/false {flag:\"waypoint\"}"}}]
tellraw @s ["",{"translate":"macroengine.flag.combat_tag","color":"white"},{"translate":"macroengine.ui.on_btn","color":"green","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/experimental/true {flag:\"combat_tag\"}"}},{"translate":"macroengine.ui.off_btn","color":"red","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/experimental/false {flag:\"combat_tag\"}"}}]
tellraw @s ["",{"translate":"macroengine.flag.scoreboard_hud","color":"white"},{"translate":"macroengine.ui.on_btn","color":"green","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/experimental/true {flag:\"scoreboard_hud\"}"}},{"translate":"macroengine.ui.off_btn","color":"red","bold":true,"click_event":{"action":"run_command","command":"/function macroengine:api/toggle/experimental/false {flag:\"scoreboard_hud\"}"}}]
tellraw @s ["",{"translate":"macroengine.ui.eq41","color":"dark_gray"}]
