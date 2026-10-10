# macroengine:api/placeholder/send
# Parses macroengine:placeholder in and prints the result in chat to the executor (@s).
# Placeholders resolve for the executor, so use `execute as <player> run function ...`
# to address someone else.
#
# Usage:
#   data modify storage macroengine:placeholder in set value "Hello %player%, you have %score:coins% coins"
#   function macroengine:api/placeholder/send
function macroengine:api/placeholder/parse_live
tellraw @s {"storage":"macroengine:placeholder","nbt":"out","interpret":true}
