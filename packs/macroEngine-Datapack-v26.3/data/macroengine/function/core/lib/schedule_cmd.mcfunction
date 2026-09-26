# ─────────────────────────────────────────────
# macroengine:core/lib/schedule_cmd
# Repeating command scheduler at a fixed interval.
#
# Girdi (macroengine:input):
# key — scheduler name (unique identifier)
# cmd — raw command to run on each trigger
# interval — repeat interval in ticks
# ─────────────────────────────────────────────

$execute if data storage macroengine:engine schedules.$(key) run data remove storage macroengine:engine schedules.$(key)

$data modify storage macroengine:engine schedules.$(key).cmd set value "$(cmd)"
$data modify storage macroengine:engine schedules.$(key).interval set value $(interval)
$data modify storage macroengine:engine queue append value {cmd:"$(cmd)", delay:$(interval)}
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_schedule_cmd","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(key)","color":"aqua"},{"translate":"macroengine.fmt.interval","color":"#555555"}]
