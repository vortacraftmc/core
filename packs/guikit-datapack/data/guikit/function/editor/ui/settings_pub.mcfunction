# macro: $(published)     "1" or "0" from the dialog checkbox
$data modify storage guikit:ed pub set value "$(published)"
execute if data storage guikit:ed {pub:"1"} run function guikit:editor/ui/set_pub_on with storage guikit:ed cur
execute if data storage guikit:ed {pub:"0"} run function guikit:editor/ui/set_pub_off with storage guikit:ed cur
data remove storage guikit:ed pub
