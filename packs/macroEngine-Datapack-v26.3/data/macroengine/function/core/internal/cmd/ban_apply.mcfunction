# macroengine:core/internal/cmd/ban_apply
# The actual ban logic.
$ban $(player) $(reason)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.cmd_ban","color":"aqua"},{"text":"$(player) $(reason)","color":"white"}]
