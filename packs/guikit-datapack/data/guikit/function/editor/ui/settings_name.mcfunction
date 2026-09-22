# macro: $(name)
$data modify storage guikit:ed name_in set value "$(name)"
function guikit:editor/ui/settings_name_put with storage guikit:ed cur
data remove storage guikit:ed name_in
