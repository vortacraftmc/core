# macroengine:systems/sound/stop
# Stops a specific sound (and category) on a target selector.
#
# Input  (macroengine:input sound):
#   target   — selector string  e.g. "@a"  "@s"
#   category — source category  (use "*" to match all categories)
#   sound    — sound event ID   (use "*" to stop all sounds in category)
#
# Usage:
#   data modify storage macroengine:input sound set value \
#     {target:"@a",category:"*",sound:"*"}
#   function macroengine:systems/sound/stop with storage macroengine:input sound

$stopsound $(target) $(category) $(sound)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.sound_stop","color":"aqua"},{"translate":"macroengine.ui.arrow_sp","color":"#555555"},{"text":"$(target)","color":"white"},{"text":" [","color":"#555555"},{"text":"$(category)","color":"green"},{"text":"] ","color":"#555555"},{"text":"$(sound)","color":"#AAAAAA"}]
