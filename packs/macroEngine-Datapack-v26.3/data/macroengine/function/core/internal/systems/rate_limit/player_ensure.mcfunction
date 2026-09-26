# macroengine:systems/rate_limit/internal/player_ensure — Auto-create player bucket from template [MACRO]
# Called by check when rule key "player:<key>:<player>" doesn't exist yet.
# Reads the template registered via rate_limit/player/config and creates the bucket.
# Input: $(key) = full compound key e.g. "player:shop:Steve"
#        $(tpl) = template key e.g. "shop"

$execute unless data storage macroengine:engine rate_limit.player_templates.$(tpl) run return 0
$data modify storage macroengine:engine rate_limit.rules.$(key) set from storage macroengine:engine rate_limit.player_templates.$(tpl)
$data modify storage macroengine:engine rate_limit.rules.$(key).hits set value []
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.rate_limit","color":"aqua"},{"translate":"macroengine.ui.init","color":"#55FFFF"},{"translate":"macroengine.debug.bucket_for","color":"#555555"},{"text":"$(key)","color":"white"}]
