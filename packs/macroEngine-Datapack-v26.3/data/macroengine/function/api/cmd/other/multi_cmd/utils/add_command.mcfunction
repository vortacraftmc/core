# ─────────────────────────────────────────────────────────────────
# macroengine:api/cmd/other/multi_cmd/utils/add_command
# Add a command to queue at runtime
#
# INPUT (storage macroengine:input):
# cmd or func → command/function to add
# ─────────────────────────────────────────────────────────────────

execute if data storage macroengine:input cmd run data modify storage macroengine:engine _mcmd_queue append value {}
execute if data storage macroengine:input cmd run data modify storage macroengine:engine _mcmd_queue[-1].cmd set from storage macroengine:input cmd

execute if data storage macroengine:input func run data modify storage macroengine:engine _mcmd_queue append value {}
execute if data storage macroengine:input func run data modify storage macroengine:engine _mcmd_queue[-1].func set from storage macroengine:input func

# # tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.multi_cmd_utils_add","color":"aqua"},{"translate":"macroengine.debug.queued","color":"green"}]
