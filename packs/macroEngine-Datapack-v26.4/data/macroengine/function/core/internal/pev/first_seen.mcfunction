# macroengine:core/internal/pev/first_seen
# @s = a player without the `macroengine.known` tag: a brand-new player, or one
# who was online when this module was first installed. Fires `joined` once.
tag @s add macroengine.known
scoreboard players set @s macroengine.ev_leave 0
function #macroengine:core/internal/pev/joined
