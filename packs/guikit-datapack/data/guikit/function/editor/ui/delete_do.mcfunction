# macro: $(menu)
$data remove storage guikit:lib menus.$(menu)
$data remove storage guikit:reg menus."guikit:m/$(menu)"
# v5: forget any /trigger guikit.last pointers at the deleted menu
$data modify storage guikit:ctx gone set value "$(menu)"
scoreboard players set #mi guikit.tmp 1
execute store result score #mn guikit.tmp run scoreboard players get #next_pid guikit.const
execute if score #mn guikit.tmp matches 1.. run function guikit:play/last_sweep
data remove storage guikit:ctx gone
