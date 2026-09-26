# ─────────────────────────────────────────────────────────────────
# macroengine:world/entity/clear_effects
# Clears all active potion effects from entities matching type+tag.
#
# INPUT : $(type) → entity type selector (e.g. "minecraft:player")
#         $(tag)  → entity tag filter
# ─────────────────────────────────────────────────────────────────

$effect clear @e[type=$(type),tag=$(tag)]
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.entity_clear_effects","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(type)[tag=$(tag)]","color":"aqua"}]
