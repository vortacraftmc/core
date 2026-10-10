# ─────────────────────────────────────────────────────────────────
# macroengine:api/placeholder/parse
# parse_live (the live component list) PLUS forms that are resolved right now,
# so they can be stored, compared or written into an item.
#
# INPUT  macroengine:placeholder in  (string); run it as and at the player the
#        placeholders are for (execute as <player> at @s run function ...)
# OUTPUT macroengine:placeholder, mirrored to macroengine:output placeholder.<key>:
#   out          live component list (selectors/scores resolve when displayed)
#   resolved     ONE component, already resolved (names, scores, NBT are plain text)
#   custom_name  resolved, italic:false on its root: write it into custom_name=
#   lore         list of resolved lines, split at every %nl%, italic:false: lore=
#   string       the resolved text as a plain string
#   string_ok    1b when `string` is complete, 0b when it was left empty because a
#                part contained a double quote or backslash
# RETURN number of components in out.
#
# Why resolved forms exist: selector, score and NBT components are resolved by the
# server only for chat, titles, books and signs. Inside an item name or lore they
# are shown raw (an unresolved "@s"). parse therefore lets the server resolve them
# once, through a short-lived scratch item (item modify), and hands back the result.
# Cost: one chest_minecart is summoned and killed per call, so use parse_live for
# per-tick or per-message display and parse only when you need these forms.
#
# Parts that are neither text nor selector/score/NBT (for example `translate`) are
# kept in resolved/custom_name/lore but are skipped in `string`.
# ─────────────────────────────────────────────────────────────────
function macroengine:api/placeholder/parse_live
function macroengine:core/internal/api/placeholder/_derive
function macroengine:core/internal/api/placeholder/_save_items
return run data get storage macroengine:placeholder out
