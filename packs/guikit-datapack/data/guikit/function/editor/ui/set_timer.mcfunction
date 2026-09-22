# macro: $(seconds)
function guikit:editor/load_state
$scoreboard players set #sec guikit.tmp $(seconds)
scoreboard players set #t20 guikit.tmp 20
scoreboard players operation #sec guikit.tmp *= #t20 guikit.tmp
execute store result storage guikit:work ticks int 1 run scoreboard players get #sec guikit.tmp
function guikit:editor/ui/settings_timer with storage guikit:ed cur
data modify storage guikit:work id set from storage guikit:ed cur.menu
function guikit:runtime/sync_one with storage guikit:work
function guikit:editor/save_state
tellraw @s {"text":"[guikit] Timeout updated.","color":"green"}
function guikit:editor/schedule_resume
