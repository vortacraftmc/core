# macroengine:core/internal/api/item/combo_marker_apply
# Internal — do not call directly. Second pass of api/item/combo_marker.
# Expects: {player:"...",slot:"...",macroengine:{...}}

$item modify entity @a[name=$(player),limit=1] $(slot) {function:"minecraft:set_components",components:{"minecraft:custom_data":{macroengine:$(macroengine)}}}
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.item_combo_marker","color":"aqua"},{"text":"$(player) ","color":"white"},{"translate":"macroengine.fmt.slot","color":"gray"}]
