# as player. Drop widget items that were drawn for a different owner.
# A stolen stack still has the click id, so it must be gone before probe.
scoreboard players set #purged guikit.tmp 0
execute store result storage guikit:ctx own int 1 run scoreboard players get @s guikit.uid
execute if items entity @s player.cursor *[custom_data~{guikit:{w:1b}}] run function guikit:internal/guard/purge_cursor with storage guikit:ctx
execute if items entity @s weapon.offhand *[custom_data~{guikit:{w:1b}}] run function guikit:internal/guard/purge_offhand with storage guikit:ctx
# clear ... 0 only counts. Skip the slot loop when the inventory has no widget item.
execute store result score #wcount guikit.tmp run clear @s *[custom_data~{guikit:{w:1b}}] 0
execute if score #wcount guikit.tmp matches 1.. run function guikit:internal/guard/purge_inv
execute if score #purged guikit.tmp matches 1.. as @a[scores={guikit.uid=1..}] run scoreboard players set @s guikit.dirty 1
