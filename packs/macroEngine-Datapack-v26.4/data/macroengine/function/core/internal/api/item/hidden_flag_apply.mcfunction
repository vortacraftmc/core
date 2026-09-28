# macroengine:core/internal/api/item/hidden_flag_apply
# Internal — do not call directly. Second pass of api/item/hidden_flag.
# Expects: {player:"...",slot:"...",macroengine:{...}}

$item modify entity @a[name=$(player),limit=1] $(slot) {function:"minecraft:set_components",components:{"minecraft:custom_data":{macroengine:$(macroengine)}}}