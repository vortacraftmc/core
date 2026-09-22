# guikit :: tick
execute as @a[scores={guikit.timer=1..}] at @s run function guikit:core/tick_player
kill @e[type=minecraft:item,nbt={Item:{components:{"minecraft:custom_data":{guikit:{w:1b}}}}}]

# player-facing menu list. trigger is permission 0; the editor itself stays /function (op).
scoreboard players enable @a guikit.open
execute as @a[scores={guikit.open=1..}] at @s run function guikit:play/from_trigger
execute as @a[tag=!guikit.welcomed] at @s run function guikit:runtime/welcome
