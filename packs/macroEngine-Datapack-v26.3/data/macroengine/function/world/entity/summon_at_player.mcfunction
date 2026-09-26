$execute as @a[name=$(player),limit=1] at @s run summon $(entity) ~ ~ ~ $(nbt)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.entity_summon_at_player","color":"aqua"},{"text":"$(player)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(entity)","color":"aqua"}]
