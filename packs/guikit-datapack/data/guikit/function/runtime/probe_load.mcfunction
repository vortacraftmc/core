# macro: $(uid)
$data modify storage guikit:sess cur set from storage guikit:sess bound.u$(uid)
execute unless data storage guikit:sess cur.mode run return 0
execute if data storage guikit:sess cur{mode:"home"} run return run function guikit:editor/home/probe
execute if data storage guikit:sess cur{mode:"edit"} run return run function guikit:editor/edit/probe
execute if data storage guikit:sess cur{mode:"pick"} run return run function guikit:editor/pick/probe
execute if data storage guikit:sess cur{mode:"browse"} run return run function guikit:browse/probe
execute if data storage guikit:sess cur{mode:"play"} run function guikit:play/probe
