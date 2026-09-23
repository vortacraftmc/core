# guikit :: tick
scoreboard players add #tick guikit.const 1
execute as @a[scores={guikit.gmsg=1..}] run scoreboard players remove @s guikit.gmsg 1
scoreboard players enable @a guikit.ack
execute as @a[scores={guikit.ack=1..}] run scoreboard players set @s guikit.ack 0

# Stolen widget stacks (same click id, different owner) must be gone before probe.
execute as @a run function guikit:internal/guard/purge
# @e is dimension-local. Also search at each player so a nether/end menu is covered.
execute as @e[type=minecraft:interaction,tag=guikit.guard] if data entity @s interaction at @s run function guikit:internal/guard/on_click
execute as @e[type=minecraft:interaction,tag=guikit.guard] if data entity @s attack at @s run function guikit:internal/guard/on_click
execute as @a at @s as @e[type=minecraft:interaction,tag=guikit.guard,distance=..8] if data entity @s interaction run function guikit:internal/guard/on_click
execute as @a at @s as @e[type=minecraft:interaction,tag=guikit.guard,distance=..8] if data entity @s attack run function guikit:internal/guard/on_click
execute as @e[type=minecraft:interaction,tag=guikit.guard] run function guikit:internal/guard/orphan
execute as @a at @s as @e[type=minecraft:interaction,tag=guikit.guard,distance=..64] run function guikit:internal/guard/orphan

execute as @a[scores={guikit.timer=1..}] at @s run function guikit:core/tick_player
kill @e[type=minecraft:item,nbt={Item:{components:{"minecraft:custom_data":{guikit:{w:1b}}}}}]

# player-facing menu list. trigger is permission 0; the editor itself stays /function (op).
scoreboard players enable @a guikit.open
scoreboard players enable @a guikit.goto
scoreboard players enable @a guikit.sort
scoreboard players enable @a guikit.filter
execute as @a[scores={guikit.open=1..}] at @s run function guikit:play/from_trigger
execute as @a[scores={guikit.goto=1..}] at @s run function guikit:browse/trig_page
execute as @a[scores={guikit.goto=..-1}] at @s run function guikit:browse/trig_page
execute as @a[scores={guikit.sort=1..}] at @s run function guikit:browse/trig_sort
execute as @a[scores={guikit.sort=..-1}] at @s run function guikit:browse/trig_sort
execute as @a[scores={guikit.filter=1..}] at @s run function guikit:browse/trig_filter
execute as @a[scores={guikit.filter=..-1}] at @s run function guikit:browse/trig_filter
execute as @a[tag=!guikit.welcomed] at @s run function guikit:runtime/welcome
