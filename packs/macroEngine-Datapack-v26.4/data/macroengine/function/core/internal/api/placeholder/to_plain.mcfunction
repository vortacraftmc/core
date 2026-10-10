# macroengine:core/internal/api/placeholder/to_plain [INTERNAL]
# Hard method: resolve any text component and write the result as a *plain string*
# into storage. No tellraw is used (tellraw has no capturable output). The output
# path is guaranteed to be a string — never a JSON/SNBT compound.
#
# Input:  storage macroengine:placeholder in.component
# Output: storage macroengine:placeholder out.string   (always string type)
#         storage macroengine:output      placeholder.string
# Return: 1 on success, 0 when in.component is missing
#
# How it works (hard method):
#   1. Summon a temporary text_display.
#   2. Write the input component to its text tag → server resolves
#      selector / score / nbt / translate / etc.
#   3. Read the resolved value back.
#   4. Prefer the top-level "text" field when present (plain visible text).
#   5. If the resolved value was already a bare string, keep it.
#   6. Otherwise fall back to an empty string (complex components cannot be
#      reliably turned into pure human-readable text in vanilla commands).
#   7. Kill the temporary entity.
#
# Notes:
#   - Nested %placeholders% are not re-parsed (same contract as parse).
#   - Hover, click, gradients, multi-extra, object sprites etc. produce ""
#     because pure command extraction of their visible text is not possible.
#   - Safe for untrusted input: only `data modify … set from` is used;
#     nothing is ever substituted into a command string.

execute unless data storage macroengine:placeholder in.component run return 0

# Ensure the output path starts clean and will end as a string
data modify storage macroengine:placeholder out.string set value ""

# Temporary text_display for server-side resolution
execute summon text_display run data modify entity @s Tags set value ["macroengine.ph.to_plain"]

# Resolve
data modify entity @e[type=text_display,tag=macroengine.ph.to_plain,limit=1] text set from storage macroengine:placeholder in.component

# Read resolved value
data modify storage macroengine:placeholder _tmp set from entity @e[type=text_display,tag=macroengine.ph.to_plain,limit=1] text

# Cleanup entity
kill @e[type=text_display,tag=macroengine.ph.to_plain]

# Prefer plain text field when the resolved component has one
execute if data storage macroengine:placeholder _tmp.text run data modify storage macroengine:placeholder out.string set from storage macroengine:placeholder _tmp.text

# If still empty, the resolved value may already be a bare string
execute unless data storage macroengine:placeholder out.string run data modify storage macroengine:placeholder out.string set from storage macroengine:placeholder _tmp

# Final safety: if anything non-string slipped through, force empty string
# (out.string must never be a compound or list)
execute if data storage macroengine:placeholder out.string{} run data modify storage macroengine:placeholder out.string set value ""
execute if data storage macroengine:placeholder out.string[] run data modify storage macroengine:placeholder out.string set value ""

# Mirror to public output storage
data modify storage macroengine:output placeholder.string set from storage macroengine:placeholder out.string

# Cleanup
data remove storage macroengine:placeholder _tmp

return 1
