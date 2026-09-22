function guikit:internal/safe_clear
data modify storage guikit:work pay.item set from storage guikit:work w.cost_item
data modify storage guikit:work pay.count set from storage guikit:work w.cost_count
execute unless data storage guikit:work pay.count run data modify storage guikit:work pay.count set value 1
function guikit:internal/pay_item with storage guikit:work pay
