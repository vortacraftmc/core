$data modify storage macroengine:engine queue append value {cmd:"$(cmd)", delay:$(delay)}
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_queue_add_cmd","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(cmd)","color":"aqua"}]
