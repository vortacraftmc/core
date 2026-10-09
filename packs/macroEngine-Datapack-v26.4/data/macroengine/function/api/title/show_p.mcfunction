# ─────────────────────────────────────────────────────────────────
# macroengine:api/title/show_p — placeholder-aware title + subtitle for @s
#
# Unlike title/show (which builds {"text":"$(title)"} and breaks on quotes or
# backslashes) this reads everything from storage, so any text is safe, and the
# text may contain %placeholders% (see api/placeholder/parse).
#
# INPUT macroengine:title in (all keys optional):
#   title     string with %placeholders%   (default: empty)
#   subtitle  string with %placeholders%   (default: empty)
#   fade_in   ticks (default 10)   stay ticks (default 70)   fade_out ticks (default 20)
#
# Usage:
#   data modify storage macroengine:title in set value {title:"Welcome %player%",subtitle:"Coins: %score:coins%"}
#   function macroengine:api/title/show_p
#   (to address another player:  execute as Steve run function macroengine:api/title/show_p)
# ─────────────────────────────────────────────────────────────────
execute unless data storage macroengine:title in.fade_in run data modify storage macroengine:title in.fade_in set value 10
execute unless data storage macroengine:title in.stay run data modify storage macroengine:title in.stay set value 70
execute unless data storage macroengine:title in.fade_out run data modify storage macroengine:title in.fade_out set value 20

data modify storage macroengine:placeholder in set value ""
execute if data storage macroengine:title in.title run data modify storage macroengine:placeholder in set from storage macroengine:title in.title
function macroengine:api/placeholder/parse
data modify storage macroengine:title t set from storage macroengine:placeholder out
execute unless data storage macroengine:title t[0] run data modify storage macroengine:title t set value [{text:""}]

data modify storage macroengine:placeholder in set value ""
execute if data storage macroengine:title in.subtitle run data modify storage macroengine:placeholder in set from storage macroengine:title in.subtitle
function macroengine:api/placeholder/parse
data modify storage macroengine:title s set from storage macroengine:placeholder out
execute unless data storage macroengine:title s[0] run data modify storage macroengine:title s set value [{text:""}]

function macroengine:api/title/_apply with storage macroengine:title in
