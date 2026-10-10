# macroengine:core/internal/pev/load
# Player-event module (pev): registers the statistic objectives and starts the
# heartbeat. Safe to run on every load.
#
# Every objective is a vanilla statistic that only ever counts up. The tick
# function turns "score >= 1" into one event and sets the score back to 0, so
# an event fires at most once per tick per player.
scoreboard objectives add macroengine.ev_death minecraft.custom:minecraft.deaths
scoreboard objectives add macroengine.ev_enchant minecraft.custom:minecraft.enchant_item
scoreboard objectives add macroengine.ev_jump minecraft.custom:minecraft.jump
scoreboard objectives add macroengine.ev_leave minecraft.custom:minecraft.leave_game
scoreboard objectives add macroengine.ev_rc_carrot minecraft.used:minecraft.carrot_on_a_stick
scoreboard objectives add macroengine.ev_rc_fungus minecraft.used:minecraft.warped_fungus_on_a_stick

# Objectives of the previous implementation (no longer written or read).
scoreboard objectives remove player_action.death
scoreboard objectives remove player_action.enchant
scoreboard objectives remove player_action.jump
scoreboard objectives remove player_action.join
scoreboard objectives remove player_action.use_coas
scoreboard objectives remove player_action.use_wfoas

schedule function macroengine:core/internal/pev/tick 1t
