$execute unless data storage macroengine:engine events.$(event) run return 0

$data modify storage macroengine:engine queue append value {func:"macroengine:events/internal/fire_deferred", delay:$(delay), event:"$(event)"}
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.event_fire_queued","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(event)","color":"aqua"}]
