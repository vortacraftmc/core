# macro: $(uid)
$data modify storage guikit:sess cur set from storage guikit:sess bound.u$(uid)
execute if data storage guikit:sess cur.alias run function guikit:runtime/remove_tag with storage guikit:sess cur
$data remove storage guikit:sess bound.u$(uid)
data remove storage guikit:sess cur
