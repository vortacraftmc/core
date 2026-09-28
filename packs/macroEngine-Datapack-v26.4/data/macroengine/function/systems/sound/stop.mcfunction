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
