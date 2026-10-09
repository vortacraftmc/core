# ======================================================================================
# macroengine:core/internal/systems/trim/_private/check_slot  [INTERNAL]
# ======================================================================================
# $(slot) — one of "head" | "chest" | "legs" | "feet" (an armor.<slot> equipment slot)
#
# Reads minecraft:trim off the item in that slot and writes present/matches
# into storage macroengine:trim result.$(slot).
# ======================================================================================

$data modify storage macroengine:trim scratch.slot set value "$(slot)"
data remove storage macroengine:trim scratch.has_trim

# does the item in this slot have ANY minecraft:trim component at all?
$execute store success storage macroengine:trim scratch.has_trim byte 1 if items entity @s armor.$(slot) *[minecraft:trim]

$execute if data storage macroengine:trim {scratch:{has_trim:1b}} run data modify storage macroengine:trim result.$(slot).present set value 1b
$execute unless data storage macroengine:trim {scratch:{has_trim:1b}} run data modify storage macroengine:trim result.$(slot).present set value 0b
$execute unless data storage macroengine:trim {scratch:{has_trim:1b}} run data modify storage macroengine:trim result.$(slot).matches set value 0b

# only bother checking the specific pattern/material if a trim is present at all
$execute if data storage macroengine:trim {scratch:{has_trim:1b}} run function macroengine:core/internal/systems/trim/_private/check_match {slot: "$(slot)"}

data remove storage macroengine:trim scratch
