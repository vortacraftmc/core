# ─────────────────────────────────────────────────────────────────
# macroengine:api/placeholder/parse
# Turns text containing %placeholders% into a ready-to-use text component list.
#
# INPUT  macroengine:placeholder in  (string)
# OUTPUT macroengine:placeholder out (list of text components)
# RETURN number of components in out.
#
# Why a component list and not a string: placeholders such as %player%,
# scores and storage values are resolved by the client/server text engine, so
# they stay live, need no escaping and cannot break out of a JSON string. The
# input is never substituted into a command line, so untrusted text (chat,
# signs, books, name tags) is safe to pass through here.
#
# Grammar
#   %name%          registered placeholder (see register_*), built-ins in load
#   %score:obj%     scoreboard objective `obj` of the executor
#   %%              a literal percent sign
#   unknown/unclosed %...% is kept as plain text
#
# Show the result with:   tellraw @s {"storage":"macroengine:placeholder","nbt":"out","interpret":true}
# or use api/placeholder/send, send_to, actionbar, title.
# ─────────────────────────────────────────────────────────────────
data modify storage macroengine:placeholder out set value []
data modify storage macroengine:placeholder segs set value []
execute unless data storage macroengine:placeholder in run return 0

# Split on '%'. Segments alternate: text, name, text, name, ... (empties kept).
data modify storage macroengine:text s set from storage macroengine:placeholder in
data modify storage macroengine:text sep set value "%"
data modify storage macroengine:text keep_empty set value 1b
data modify storage macroengine:text n set value 0
function macroengine:core/internal/text/split
data modify storage macroengine:placeholder segs set from storage macroengine:text out
function macroengine:core/internal/text/reset

scoreboard players set #ph_name macroengine.tmp 0
function macroengine:core/internal/api/placeholder/_loop
data remove storage macroengine:placeholder segs
data remove storage macroengine:placeholder cur
data remove storage macroengine:placeholder name
data remove storage macroengine:placeholder pre
data remove storage macroengine:placeholder obj
return run data get storage macroengine:placeholder out
