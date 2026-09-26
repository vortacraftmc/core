# macroengine:systems/flag/list_systems — List all tick systems with their current on/off state
tellraw @s [{"translate":"macroengine.sys.tick_header","color":"gold","bold":true}]
tellraw @s [{"translate":"macroengine.sys.time","color":"gray"},{"score":{"name":"#sys_time","objective":"macroengine.tick_flags"},"color":"yellow"}]
tellraw @s [{"translate":"macroengine.sys.player","color":"gray"},{"score":{"name":"#sys_player","objective":"macroengine.tick_flags"},"color":"yellow"}]
tellraw @s [{"translate":"macroengine.sys.queue","color":"gray"},{"score":{"name":"#sys_queue","objective":"macroengine.tick_flags"},"color":"yellow"}]
tellraw @s [{"translate":"macroengine.sys.hud","color":"gray"},{"score":{"name":"#sys_hud","objective":"macroengine.tick_flags"},"color":"yellow"}]
tellraw @s [{"translate":"macroengine.sys.admin","color":"gray"},{"score":{"name":"#sys_admin","objective":"macroengine.tick_flags"},"color":"yellow"}]
