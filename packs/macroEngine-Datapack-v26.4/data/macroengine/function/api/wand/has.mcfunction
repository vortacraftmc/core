# ─────────────────────────────────────────────────────────────────
# macroengine:api/wand/has
# Does the player hold a specific wand in their main hand?
#
# INPUT:
#   $(player) → player name
#   $(tag)    → wand tag to check
# OUTPUT:
# macroengine:output result → 1b (found) / 0b (not found)
# ─────────────────────────────────────────────────────────────────

data modify storage macroengine:output result set value 0b
$execute as @a[name=$(player),limit=1] if items entity @s weapon.mainhand *[minecraft:custom_data~{wand:"$(tag)"}] run data modify storage macroengine:output result set value 1b