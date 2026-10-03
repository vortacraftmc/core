data modify storage macroengine:output result set value 1b

$execute if data storage macroengine:engine config.$(key) run data modify storage macroengine:output result set value 0b
$execute if data storage macroengine:engine config.$(key) run return 0

$data modify storage macroengine:engine config.$(key) set value "$(value)"
