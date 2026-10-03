tag @s remove guikit.dialog
function guikit:editor/load_state
execute if data storage guikit:ed cur{dialog:"slot"} run dialog show @s guikit:slot
execute if data storage guikit:ed cur{dialog:"tools"} run dialog show @s guikit:tools
execute if data storage guikit:ed cur{dialog:"help"} run dialog show @s guikit:help
execute if data storage guikit:ed cur{dialog:"delete_menu"} run dialog show @s guikit:delete_menu
data remove storage guikit:ed cur.dialog
function guikit:editor/save_state
