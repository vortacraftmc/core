# macroengine:core/internal/api/item/owner_tag_apply
# Internal — do not call directly. Second pass of api/item/owner_tag.
# Expects: {player:"...",slot:"...",macroengine:{...}}

$item modify entity @a[name=$(player),limit=1] $(slot) {function:"minecraft:set_components",components:{"minecraft:custom_data":{macroengine:$(macroengine)}}}