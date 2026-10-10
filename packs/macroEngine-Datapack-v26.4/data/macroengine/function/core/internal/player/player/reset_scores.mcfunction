# macroEngine player module — zero every event counter after dispatch so
# each statistic fires at most once per tick.

scoreboard players set @s player_action.fly 0
scoreboard players set @s player_action.walk 0
scoreboard players set @s player_action.fall 0
scoreboard players set @s player_action.climb 0
scoreboard players set @s player_action.aviate 0
