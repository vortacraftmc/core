# ─────────────────────────────────────────────────────────────────
# macroengine:core/lib/once_per_player_reset
# Deletes the once_per_player record — function can run again.
#  Girdi : $(player), $(key)
# ─────────────────────────────────────────────────────────────────

$data remove storage macroengine:engine once_per_player.$(player).$(key)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_once_per_player_reset","color":"aqua"},{"text":"$(player):$(key) reset","color":"yellow"}]
