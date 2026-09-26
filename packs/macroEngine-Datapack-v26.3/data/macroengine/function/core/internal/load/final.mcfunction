data modify storage macroengine:engine global.version set value "v26.3"
scoreboard players set #vortacraftmc.packs.macroengine.version macroengine.meta 620

tellraw @a ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.load.loaded","color":"green"}]

# Informational notice for operators: strict_gating is a permission
# enforcement flag (see core/internal/security/check_all + config.mcfunction).
# Ships ON by default on fresh installs; every *_min_level threshold defaults
# to 0 (everyone passes) until an admin raises one. This message does not
# change gate behavior; it only surfaces the flag's current state to ops.
execute if data storage macroengine:engine flags.experimental{strict_gating:1b} run tellraw @a[tag=macroengine.admin] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.gating.on","color":"gray"},{"translate":"macroengine.gating.manage","color":"gray"},{"translate":"macroengine.cmd.exp_show","color":"yellow","clickEvent":{"action":"suggest_command","value":"/function macroengine:api/toggle/experimental/show"}}]
execute unless data storage macroengine:engine flags.experimental{strict_gating:1b} run tellraw @a[tag=macroengine.admin] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.gating.off","color":"gray"},{"translate":"macroengine.gating.enable","color":"gray"},{"translate":"macroengine.cmd.exp_show","color":"yellow","clickEvent":{"action":"suggest_command","value":"/function macroengine:api/toggle/experimental/show"}}]

# (formerly macroengine:core/internal/load/post_load — used to be triggered
# via the load:post_load tag, now the natural final step of the setup flow)
# Hook so other packs/extensions can add to the #macroengine:init tag
# (-> #macroengine:events/on_load) to say "run when macroEngine is fully loaded".
# 20t delay: this final.mcfunction already runs at t+16 (main->all->final
# chain), +4 ticks leaves extra margin.
# # tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.debug.sched_init","color":"gray"}]
schedule function #macroengine:init 2t replace
