# macro: $(rate)     only off / s1 / s3 / s5
function guikit:editor/load_state
data modify storage guikit:work ticks set value 20
$data modify storage guikit:ed rate set value "$(rate)"
execute if data storage guikit:ed {rate:"off"} run data modify storage guikit:work ticks set value 0
execute if data storage guikit:ed {rate:"s1"} run data modify storage guikit:work ticks set value 20
execute if data storage guikit:ed {rate:"s3"} run data modify storage guikit:work ticks set value 60
execute if data storage guikit:ed {rate:"s5"} run data modify storage guikit:work ticks set value 100
function guikit:editor/ui/settings_refresh with storage guikit:ed cur
data remove storage guikit:ed rate
data modify storage guikit:work id set from storage guikit:ed cur.menu
function guikit:runtime/sync_one with storage guikit:work
function guikit:editor/save_state
tellraw @s {"text":"[guikit] Auto refresh updated.","color":"green"}
function guikit:editor/schedule_resume
