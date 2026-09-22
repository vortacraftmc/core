# macro: $(n)
$data modify storage guikit:lib menus.m$(n) set value {n:$(n),name:"Menu $(n)",container:"chest_minecart",timer:900,published:1b,pages:[{widgets:[]}]}
$data modify storage guikit:lib order append value "m$(n)"
$function guikit:runtime/sync_one {id:"m$(n)"}
data modify storage guikit:ed cur.screen set value "edit"
data modify storage guikit:ed cur.page set value 0
data modify storage guikit:ed cur.slot set value -1
data modify storage guikit:ed cur.list_page set value 0
$function guikit:editor/create_menu_id {menu:"m$(n)"}
function guikit:editor/save_state
function guikit:api/close
function guikit:editor/schedule_resume
