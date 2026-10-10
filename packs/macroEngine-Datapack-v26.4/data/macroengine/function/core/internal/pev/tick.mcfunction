# macroengine:core/internal/pev/tick
# Heartbeat. Only players whose score changed are touched; nobody else is
# selected, so an idle server pays for a handful of empty selectors per tick.
# Handlers run as the player, at the player's position.
schedule function macroengine:core/internal/pev/tick 1t

# Players seen for the first time (no tag yet), then returning players
execute as @a[tag=!macroengine.known] at @s run function macroengine:core/internal/pev/first_seen
execute as @a[scores={macroengine.ev_leave=1..}] at @s run function macroengine:core/internal/pev/rejoined

execute as @a[scores={macroengine.ev_death=1..}] at @s run function #macroengine:core/internal/pev/died
scoreboard players set @a[scores={macroengine.ev_death=1..}] macroengine.ev_death 0

execute as @a[scores={macroengine.ev_enchant=1..}] at @s run function #macroengine:core/internal/pev/enchanted
scoreboard players set @a[scores={macroengine.ev_enchant=1..}] macroengine.ev_enchant 0

execute as @a[scores={macroengine.ev_jump=1..}] at @s run function #macroengine:core/internal/pev/jumped
scoreboard players set @a[scores={macroengine.ev_jump=1..}] macroengine.ev_jump 0

execute as @a[scores={macroengine.ev_rc_carrot=1..}] at @s run function #macroengine:core/internal/pev/right_click
scoreboard players set @a[scores={macroengine.ev_rc_carrot=1..}] macroengine.ev_rc_carrot 0

execute as @a[scores={macroengine.ev_rc_fungus=1..}] at @s run function #macroengine:core/internal/pev/right_click
scoreboard players set @a[scores={macroengine.ev_rc_fungus=1..}] macroengine.ev_rc_fungus 0
