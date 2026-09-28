# macroengine:core/internal/api/item/durability_overlay_apply
# Internal — do not call directly. Second pass of api/item/durability_overlay.
# Expects: {player:"...",slot:"...",macroengine:{...}}

$item modify entity @a[name=$(player),limit=1] $(slot) {function:"minecraft:set_components",components:{"minecraft:custom_data":{macroengine:$(macroengine)}}}