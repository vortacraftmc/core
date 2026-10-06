execute if score @s guikit.bsort matches 1 run data modify storage guikit:w lore append value {text:"Newest first",color:"gray",italic:false}
execute unless score @s guikit.bsort matches 1 run data modify storage guikit:w lore append value {text:"Oldest first",color:"gray",italic:false}
execute unless score @s guikit.bfilt matches 1..7 run data modify storage guikit:w lore append value {text:"All containers",color:"gray",italic:false}
execute if score @s guikit.bfilt matches 1 run data modify storage guikit:w lore append value {text:"Chest only",color:"gray",italic:false}
execute if score @s guikit.bfilt matches 2 run data modify storage guikit:w lore append value {text:"Hopper only",color:"gray",italic:false}
execute if score @s guikit.bfilt matches 3 run data modify storage guikit:w lore append value {text:"Barrel only",color:"gray",italic:false}
execute if score @s guikit.bfilt matches 4 run data modify storage guikit:w lore append value {text:"Ender chest only",color:"gray",italic:false}
execute if score @s guikit.bfilt matches 5 run data modify storage guikit:w lore append value {text:"Trapped chest only",color:"gray",italic:false}
execute if score @s guikit.bfilt matches 6 run data modify storage guikit:w lore append value {text:"Shulker box only",color:"gray",italic:false}
execute if score @s guikit.bfilt matches 7 run data modify storage guikit:w lore append value {text:"Copper chest only",color:"gray",italic:false}
