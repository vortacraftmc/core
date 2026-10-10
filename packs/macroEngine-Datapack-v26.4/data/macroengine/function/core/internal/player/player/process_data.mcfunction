# macroEngine player module — translate this tick's statistics into state
# tags and one-shot event hooks.

# Movement counters -> tags
execute if score @s player_action.fly matches 1.. run tag @s add player_action.flying
execute if score @s player_action.walk matches 1.. run tag @s add player_action.walking
execute if score @s player_action.fall matches 1.. run tag @s add player_action.falling
execute if score @s player_action.climb matches 1.. run tag @s add player_action.climbing
execute if score @s player_action.aviate matches 1.. run tag @s add player_action.elyra_flying

# Entity-state predicates -> tags
execute if predicate macroengine:core/internal/player/swimming run tag @s add player_action.swimming
execute if predicate macroengine:core/internal/player/sneaking run tag @s add player_action.sneaking
execute if predicate macroengine:core/internal/player/sprinting run tag @s add player_action.sprinting

# Mount predicates -> tags
execute if predicate macroengine:core/internal/player/riding_pig run tag @s add player_action.riding_pig
execute if predicate macroengine:core/internal/player/riding_boat run tag @s add player_action.riding_boat
execute if predicate macroengine:core/internal/player/riding_mule run tag @s add player_action.riding_mule
execute if predicate macroengine:core/internal/player/riding_llama run tag @s add player_action.riding_llama
execute if predicate macroengine:core/internal/player/riding_horse run tag @s add player_action.riding_horse
execute if predicate macroengine:core/internal/player/riding_donkey run tag @s add player_action.riding_donkey
execute if predicate macroengine:core/internal/player/riding_strider run tag @s add player_action.riding_strider
execute if predicate macroengine:core/internal/player/riding_minecart run tag @s add player_action.riding_minecart

# One-shot events (death, jump, enchant, right click, join) live in
# macroengine:core/internal/pev.
