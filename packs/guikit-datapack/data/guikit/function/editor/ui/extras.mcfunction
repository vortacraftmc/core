# macro: $(confirm) $(cd) $(need)     tokens come from guikit:extras; only the known ones are stored
function guikit:editor/load_state
scoreboard players set #b guikit.tmp -1
execute store result score #b guikit.tmp run data get storage guikit:ed cur.slot
execute unless score #b guikit.tmp matches 0..26 run return run function guikit:editor/schedule_resume
function guikit:editor/ui/load_widget
execute if score #ok guikit.tmp matches 0 run return run function guikit:editor/schedule_resume
execute if data storage guikit:ed widget{kind:"decor"} run return run function guikit:editor/schedule_resume
$data modify storage guikit:ed confirm set value "$(confirm)"
$data modify storage guikit:ed cd set value "$(cd)"
$data modify storage guikit:ed need set value "$(need)"
execute if data storage guikit:ed {confirm:"1"} run data modify storage guikit:ed widget.confirm set value 1b
execute if data storage guikit:ed {confirm:"0"} run data remove storage guikit:ed widget.confirm
execute if data storage guikit:ed {cd:"none"} run data remove storage guikit:ed widget.cd
execute if data storage guikit:ed {cd:"s3"} run data modify storage guikit:ed widget.cd set value 60
execute if data storage guikit:ed {cd:"s10"} run data modify storage guikit:ed widget.cd set value 200
execute if data storage guikit:ed {cd:"s30"} run data modify storage guikit:ed widget.cd set value 600
execute if data storage guikit:ed {need:"none"} run data remove storage guikit:ed widget.need
execute if data storage guikit:ed {need:"vip"} run data modify storage guikit:ed widget.need set value "vip"
execute if data storage guikit:ed {need:"member"} run data modify storage guikit:ed widget.need set value "member"
execute if data storage guikit:ed {need:"staff"} run data modify storage guikit:ed widget.need set value "staff"
data remove storage guikit:ed confirm
data remove storage guikit:ed cd
data remove storage guikit:ed need
function guikit:editor/edit/upsert
function guikit:editor/save_state
tellraw @s {"text":"[guikit] Saved click rules.","color":"green"}
function guikit:editor/schedule_resume
