scoreboard players set #len guikit.tmp 0
execute store result score #len guikit.tmp run data get storage guikit:ed name_in
execute unless score #len guikit.tmp matches 1.. run tellraw @s {"text":"[guikit] Type a name, or choose the held item's anvil name.","color":"red"}
execute unless score #len guikit.tmp matches 1.. run return 0
data modify storage guikit:ed widget.name set value {text:"",italic:false}
data modify storage guikit:ed widget.name.text set from storage guikit:ed name_in
scoreboard players set #named guikit.tmp 1
