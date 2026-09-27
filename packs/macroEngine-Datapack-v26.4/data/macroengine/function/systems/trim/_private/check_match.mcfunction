# ======================================================================================
# macroengine:systems/trim/_private/check_match  [INTERNAL]
# ======================================================================================
# $(slot) — armor slot already confirmed to have a minecraft:trim component
#           (see check_slot). Tests it against the exact
#           circuit + overload combination this module cares about.
# ======================================================================================

$execute store success storage macroengine:trim result.$(slot).matches byte 1 if items entity @s armor.$(slot) *[minecraft:trim={pattern:"macroengine:circuit",material:"macroengine:overload"}]

$execute if data storage macroengine:trim {result:{$(slot):{matches:1b}}} run data modify storage macroengine:trim result.any_matches set value 1b
$execute if data storage macroengine:trim {result:{$(slot):{matches:1b}}} run function macroengine:systems/trim/_private/fire_matched {slot: "$(slot)"}
