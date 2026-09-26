# ─────────────────────────────────────────────────────────────────
# macroengine:systems/geo/region_watch/list
# Shows all registered regions to debug players.
# ─────────────────────────────────────────────────────────────────

tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.header.region_watches","color":"aqua"}]
execute if data storage macroengine:engine region_watches run tellraw @a[tag=macroengine.debug] ["",{"text":" ","color":"#555555"},{"plain":true ,"storage":"macroengine:engine","nbt":"region_watches","interpret":false,"color":"yellow"}]
execute unless data storage macroengine:engine region_watches run tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.geo.no_regions2","color":"gray","italic":true}]
tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.ui.sep32","color":"#555555"}]
