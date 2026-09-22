# macro: $(menu)     menu id is m<number>
data remove storage guikit:work menu
$data modify storage guikit:work menu set from storage guikit:lib menus.$(menu)
