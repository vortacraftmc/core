# macro: $(msg) $(lore)
$data modify storage guikit:ed widget.msg set value "$(msg)"
$data modify storage guikit:ed lore_in set value "$(lore)"
data modify storage guikit:ed widget.lore set value [{text:"",color:"gray",italic:false}]
data modify storage guikit:ed widget.lore[0].text set from storage guikit:ed lore_in
data remove storage guikit:ed lore_in
