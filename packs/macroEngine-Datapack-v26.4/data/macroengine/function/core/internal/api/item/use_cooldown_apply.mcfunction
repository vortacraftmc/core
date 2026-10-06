# macroengine:core/internal/api/item/use_cooldown_apply
# Internal — do not call directly. Final pass of api/item/use_cooldown.
# Expects: {player:"...",slot:"...",macroengine:{...}}

$item modify entity @a[name=$(player),limit=1] $(slot) {function:"minecraft:set_components",components:{"minecraft:custom_data":{macroengine:$(macroengine)}}}