# macroengine:core/internal/pev/rejoined
# @s = a known player whose leave_game statistic went up, i.e. they reconnected.
scoreboard players set @s macroengine.ev_leave 0
function #macroengine:core/internal/pev/joined
