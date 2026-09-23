function guikit:internal/clear/w
data modify storage guikit:w slot set value 23
data modify storage guikit:w item set value "minecraft:hopper"
data modify storage guikit:w id set value "bfilt"
data modify storage guikit:w type set value "tool"
data modify storage guikit:w name set value {text:"Filter: all",italic:false}
execute if score @s guikit.bfilt matches 1 run data modify storage guikit:w name set value {text:"Filter: chest",color:"aqua",italic:false}
execute if score @s guikit.bfilt matches 2 run data modify storage guikit:w name set value {text:"Filter: hopper",color:"aqua",italic:false}
execute if score @s guikit.bfilt matches 3 run data modify storage guikit:w name set value {text:"Filter: barrel",color:"aqua",italic:false}
execute if score @s guikit.bfilt matches 4 run data modify storage guikit:w name set value {text:"Filter: ender chest",color:"aqua",italic:false}
execute if score @s guikit.bfilt matches 5 run data modify storage guikit:w name set value {text:"Filter: trapped chest",color:"aqua",italic:false}
execute if score @s guikit.bfilt matches 6 run data modify storage guikit:w name set value {text:"Filter: shulker",color:"aqua",italic:false}
execute if score @s guikit.bfilt matches 7 run data modify storage guikit:w name set value {text:"Filter: copper chest",color:"aqua",italic:false}
data modify storage guikit:w lore set value [{text:"Click to cycle",color:"gray",italic:false},{text:"/trigger guikit.filter",color:"dark_gray",italic:false}]
function guikit:widget/draw
