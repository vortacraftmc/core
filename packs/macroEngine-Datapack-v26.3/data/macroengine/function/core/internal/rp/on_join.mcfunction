# Called from #macroengine:events/on_join — enforce resource pack notice once per session
execute if entity @s[tag=macroengine.rp_warned] run return 0
function macroengine:core/internal/rp/check
