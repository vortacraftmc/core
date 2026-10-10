# macroengine:core/internal/api/placeholder/to_plain [INTERNAL]
# Hard method: resolve any text component (text / selector / score / nbt /
# translate / array / extra) and write a *plain string* into storage.
# Never returns a compound or list — out.string is always a string.
# No tellraw is used.
#
# Input:  storage macroengine:placeholder in.component
# Output: storage macroengine:placeholder out.string
#         storage macroengine:output      placeholder.string
# Return: 1 on success, 0 when in.component is missing
#
# Flatten rules (after text_display resolution):
#   1. Bare string            → that string
#   2. {text:"…"}             → text field
#   3. Array of components    → each element's text (or the element if string)
#   4. Component with extra   → root text + every extra[i].text (unlimited)
#   5. Fragments concatenated via macroengine:core/internal/text/concat
#   6. Anything that still isn't a string → ""

execute unless data storage macroengine:placeholder in.component run return 0

data modify storage macroengine:placeholder out.string set value ""
data modify storage macroengine:placeholder _frags set value []

# --- resolve via temporary text_display ---
execute summon text_display run data modify entity @s Tags set value ["macroengine.ph.to_plain"]
data modify entity @e[type=text_display,tag=macroengine.ph.to_plain,limit=1] text set from storage macroengine:placeholder in.component
data modify storage macroengine:placeholder _tmp set from entity @e[type=text_display,tag=macroengine.ph.to_plain,limit=1] text
kill @e[type=text_display,tag=macroengine.ph.to_plain]

# --- case: resolved value is already a bare string ---
execute unless data storage macroengine:placeholder _tmp{} unless data storage macroengine:placeholder _tmp[] run data modify storage macroengine:placeholder _frags append from storage macroengine:placeholder _tmp

# --- case: top-level text field ---
execute if data storage macroengine:placeholder _tmp.text run data modify storage macroengine:placeholder _frags append from storage macroengine:placeholder _tmp.text

# --- case: resolved value is an array of components/strings ---
execute if data storage macroengine:placeholder _tmp[0] run data modify storage macroengine:placeholder _walk set from storage macroengine:placeholder _tmp
execute if data storage macroengine:placeholder _tmp[0] run function macroengine:core/internal/api/placeholder/to_plain_walk_array

# --- case: extra[] children (selector/score resolve often lands here) ---
execute if data storage macroengine:placeholder _tmp.extra[0] run data modify storage macroengine:placeholder _walk set from storage macroengine:placeholder _tmp.extra
execute if data storage macroengine:placeholder _tmp.extra[0] run function macroengine:core/internal/api/placeholder/to_plain_walk_array

# --- concatenate collected fragments into a single string ---
data modify storage macroengine:text list set from storage macroengine:placeholder _frags
execute if data storage macroengine:placeholder _frags[0] run function macroengine:core/internal/text/concat
execute if data storage macroengine:text out run data modify storage macroengine:placeholder out.string set from storage macroengine:text out

# --- final type guard: never leave a compound/list in out.string ---
execute if data storage macroengine:placeholder out.string{} run data modify storage macroengine:placeholder out.string set value ""
execute if data storage macroengine:placeholder out.string[] run data modify storage macroengine:placeholder out.string set value ""

# mirror
data modify storage macroengine:output placeholder.string set from storage macroengine:placeholder out.string

# cleanup
data remove storage macroengine:placeholder _tmp
data remove storage macroengine:placeholder _frags
data remove storage macroengine:placeholder _walk
data remove storage macroengine:placeholder _nested
data remove storage macroengine:placeholder _nested2
data remove storage macroengine:text list
data remove storage macroengine:text out
data remove storage macroengine:text err
data remove storage macroengine:text pc
data remove storage macroengine:text cl

return 1
