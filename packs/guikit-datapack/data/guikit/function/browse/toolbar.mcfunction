function guikit:internal/clear/w
data modify storage guikit:w slot set value 18
data modify storage guikit:w item set value "minecraft:arrow"
data modify storage guikit:w id set value "bprev"
data modify storage guikit:w type set value "tool"
data modify storage guikit:w name set value {text:"Previous page",italic:false}
data modify storage guikit:w lore set value []
function guikit:widget/draw
function guikit:browse/page_label
function guikit:internal/clear/w
data modify storage guikit:w slot set value 20
data modify storage guikit:w item set value "minecraft:arrow"
data modify storage guikit:w id set value "bnext"
data modify storage guikit:w type set value "tool"
data modify storage guikit:w name set value {text:"Next page",italic:false}
data modify storage guikit:w lore set value []
function guikit:widget/draw
function guikit:browse/sort_button
function guikit:internal/clear/w
data modify storage guikit:w slot set value 22
data modify storage guikit:w item set value "minecraft:knowledge_book"
data modify storage guikit:w id set value "bhelp"
data modify storage guikit:w type set value "tool"
data modify storage guikit:w name set value {text:"Help",color:"aqua",italic:false}
data modify storage guikit:w lore set value [{text:"Page, sort, and filter commands",color:"gray",italic:false}]
function guikit:widget/draw
function guikit:browse/filter_button
function guikit:internal/clear/w
data modify storage guikit:w slot set value 24
data modify storage guikit:w item set value "minecraft:clock"
data modify storage guikit:w id set value "binfo"
data modify storage guikit:w type set value "decor"
data modify storage guikit:w name set value {text:"Refreshes every second",color:"aqua",italic:false}
data modify storage guikit:w lore set value [{text:"New menus appear without reopening",color:"gray",italic:false}]
function guikit:widget/draw
function guikit:internal/clear/w
data modify storage guikit:w slot set value 26
data modify storage guikit:w item set value "minecraft:barrier"
data modify storage guikit:w id set value "bclose"
data modify storage guikit:w type set value "tool"
data modify storage guikit:w name set value {text:"Close",color:"red",italic:false}
data modify storage guikit:w lore set value []
function guikit:widget/draw
