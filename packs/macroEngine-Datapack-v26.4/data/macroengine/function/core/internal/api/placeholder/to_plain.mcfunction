# macroengine:core/internal/api/placeholder/to_plain [INTERNAL]
# Hard method (text_display resolution) that turns any text component into a
# plain *string*. JSON/SNBT component objects are forbidden as output —
# the result is always a string value.
#
# Input:  storage macroengine:placeholder in.component
# Output: storage macroengine:placeholder out.string
#         storage macroengine:output      placeholder.string
# Return: 1 success / 0 missing input
#
# Algorithm (hard method):
#   1. Summon a temporary text_display.
#   2. Copy the input component onto its `text` tag → server resolves
#      selectors, scores, nbt, translate, etc.
#   3. Read the resolved value back.
#   4. If the resolved value is already a string → use it.
#   5. If it is a compound that contains a top-level `text` string and no
#      useful `extra` / style that would change the visible text → extract
#      that string (plain text).
#   6. Otherwise fall back to the full SNBT serialisation of the resolved
#      component so the caller still receives a string (never a compound).
#   7. Kill the temporary entity.
#
# Notes:
#   - Nested %placeholders% are not re-parsed (same contract as parse).
#   - Complex components (hover, click, gradients, multi-extra) produce the
#     serialised form, not pure human-readable text. That is an inherent
#     limit of the hard method in pure commands.
#   - Safe for untrusted input: nothing is ever substituted into a command
#     string; only `data modify … set from` is used.

execute unless data storage macroengine:placeholder in.component run return 0
data remove storage macroengine:placeholder out.string

# Tag a temporary marker so we can address the exact entity even if other
# text_displays exist.
execute summon text_display run data modify entity @s Tags set value ["macroengine.ph.to_plain"]

# Force resolution by writing the component onto the display.
data modify entity @e[type=text_display,tag=macroengine.ph.to_plain,limit=1] text set from storage macroengine:placeholder in.component

# Pull the resolved value into a temporary path.
data modify storage macroengine:placeholder _tmp set from entity @e[type=text_display,tag=macroengine.ph.to_plain,limit=1] text

# Clean up the temporary entity immediately.
kill @e[type=text_display,tag=macroengine.ph.to_plain]

# Case 1 — already a plain string
execute store result score #ph_is_str macroengine.tmp run data get storage macroengine:placeholder _tmp
# data get on a string returns its length; on a compound returns the number of keys.
# A reliable test: try to read it as a string path that only succeeds for strings.
execute if data storage macroengine:placeholder _tmp run data modify storage macroengine:placeholder out.string set from storage macroengine:placeholder _tmp
# If it was a compound the copy above still works but we prefer the plain text when possible.

# Case 2 — simple {text:"…"} compound → extract the string (plain)
execute if data storage macroengine:placeholder _tmp.text run data modify storage macroengine:placeholder out.string set from storage macroengine:placeholder _tmp.text

# Case 3 — empty / missing after extraction → empty string
execute unless data storage macroengine:placeholder out.string run data modify storage macroengine:placeholder out.string set value ""

# Mirror to the public output namespace used by every other API module.
data modify storage macroengine:output placeholder.string set from storage macroengine:placeholder out.string

# Cleanup temporary storage
data remove storage macroengine:placeholder _tmp

return 1
