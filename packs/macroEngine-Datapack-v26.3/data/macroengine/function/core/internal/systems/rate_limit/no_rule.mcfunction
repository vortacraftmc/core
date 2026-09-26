# macroengine:systems/rate_limit/internal/no_rule — Warn when check called on unregistered key [MACRO]
# Input: $(key)
# Fail-open: result stays 1b (ALLOWED) so callers aren't broken by missing config.

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.rate_limit_check","color":"aqua"},{"translate":"macroengine.debug.warn_tag","color":"#FFAA00"},{"translate":"macroengine.debug.no_rule","color":"#555555"},{"text":"$(key)","color":"#FF5555"},{"translate":"macroengine.debug.fail_open","color":"#555555"}]
