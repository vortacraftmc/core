# optional: if the player is holding an item, use it as the icon
execute if data entity @s SelectedItem.id run data modify storage guikit:ed widget.item set from entity @s SelectedItem.id
