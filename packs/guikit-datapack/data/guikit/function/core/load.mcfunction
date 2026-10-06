# guikit :: load
scoreboard objectives add guikit.timer dummy
scoreboard objectives add guikit.tmax dummy
scoreboard objectives add guikit.click dummy
scoreboard objectives add guikit.page dummy
scoreboard objectives add guikit.tmp dummy
scoreboard objectives add guikit.rand dummy
scoreboard objectives add guikit.cd dummy
scoreboard objectives add guikit.dirty dummy
scoreboard objectives add guikit.uid dummy
scoreboard objectives add guikit.const dummy
scoreboard objectives add guikit.slots dummy
scoreboard objectives add guikit.drop minecraft.custom:minecraft.drop
scoreboard objectives add guikit.pid dummy
scoreboard objectives add guikit.var dummy
scoreboard objectives add guikit.open trigger
scoreboard objectives add guikit.goto trigger
scoreboard objectives add guikit.sort trigger
scoreboard objectives add guikit.filter trigger
scoreboard objectives add guikit.arm dummy
scoreboard objectives add guikit.armt dummy
scoreboard objectives add guikit.gmsg dummy
scoreboard objectives add guikit.ack trigger
scoreboard objectives add guikit.bpage dummy
scoreboard objectives add guikit.bsort dummy
scoreboard objectives add guikit.bfilt dummy
scoreboard objectives add guikit.rf dummy
scoreboard objectives add guikit.rfiv dummy
scoreboard objectives add guikit.last trigger
scoreboard objectives add guikit.close trigger

scoreboard players set #version guikit.const 5
# uid counter is only initialised once so uids stay unique across reloads
execute unless score #next_uid guikit.const matches 0.. run scoreboard players set #next_uid guikit.const 1
execute unless score #next_pid guikit.const matches 1.. run scoreboard players set #next_pid guikit.const 1
execute unless score #next_menu guikit.const matches 1.. run scoreboard players set #next_menu guikit.const 1
execute unless score #tick guikit.const matches 0.. run scoreboard players set #tick guikit.const 0
scoreboard players enable @a guikit.ack

# transient scratch storage / scores are dropped on every reload (stale state from a previous run)
function guikit:internal/clear/in
function guikit:internal/clear/tmp
function guikit:internal/btn/clear_cur

# carts that lost their owner across a reload / relog are removed
function guikit:internal/sweep/orphans

# registry is rebuilt on every reload by the #guikit:register listeners
data modify storage guikit:reg menus set value {}
function guikit:internal/summon/builtin
data modify storage guikit:cont bound set value {}
data modify storage guikit:btn defs set value {}
function #guikit:register
