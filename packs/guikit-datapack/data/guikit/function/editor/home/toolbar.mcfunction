function guikit:internal/clear/w
data modify storage guikit:w slot set value 18
data modify storage guikit:w item set value "minecraft:arrow"
data modify storage guikit:w id set value "hprev"
data modify storage guikit:w type set value "tool"
data modify storage guikit:w name set value {text:"Previous page",italic:false}
data modify storage guikit:w lore set value []
function guikit:widget/draw
function guikit:internal/clear/w
data modify storage guikit:w slot set value 20
data modify storage guikit:w item set value "minecraft:arrow"
data modify storage guikit:w id set value "hnext"
data modify storage guikit:w type set value "tool"
data modify storage guikit:w name set value {text:"Next page",italic:false}
data modify storage guikit:w lore set value []
function guikit:widget/draw
function guikit:editor/home/page_label
execute if data storage guikit:sess cur{mode:"pick"} run function guikit:editor/pick/cancel_button
execute unless data storage guikit:sess cur{mode:"pick"} run function guikit:editor/home/new_button
function guikit:internal/clear/w
data modify storage guikit:w slot set value 26
data modify storage guikit:w item set value "minecraft:barrier"
data modify storage guikit:w id set value "hclose"
data modify storage guikit:w type set value "tool"
data modify storage guikit:w name set value {text:"Close",color:"red",italic:false}
data modify storage guikit:w lore set value []
function guikit:widget/draw
