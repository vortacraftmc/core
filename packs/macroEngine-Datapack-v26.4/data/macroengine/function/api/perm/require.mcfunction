# ======================================================================================
# macroengine:api/perm/require
# ======================================================================================
# GUARD for the caller (@s). Put it at the top of any function that must be privileged.
# Passes when @s has tag macroengine.admin OR tag perm.<name> (set by api/perm/grant).
# On denial: sound + translated message + audit entry (action "perm.denied").
#
# The permission name is checked with systems/validate/safe_name BEFORE it reaches a
# macro line, so a hostile name cannot inject commands into the tag test.
#
# NOT A MACRO FUNCTION - the name is passed through storage, not as a macro argument.
#
# INPUT  (storage macroengine:perm_require):  in.perm   e.g. "shop.use"
# OUTPUT: return value 1 = allowed, 0 = denied.  macroengine:output result 1b / 0b.
#
# A server/console executor (no entity: load, tick, schedule, command block) is
# treated as trusted and passes, same convention as api/perm/grant.
#
# USAGE (first lines of a privileged function):
#   data modify storage macroengine:perm_require in.perm set value "shop.use"
#   execute unless function macroengine:api/perm/require run return 0
# ======================================================================================

data modify storage macroengine:output result set value 0b
execute unless entity @s run data modify storage macroengine:output result set value 1b
execute unless entity @s run return 1

data remove storage macroengine:validate in
data modify storage macroengine:validate in.value set from storage macroengine:perm_require in.perm
function macroengine:systems/validate/safe_name
execute unless data storage macroengine:validate out{valid:1b} run function macroengine:core/internal/api/perm/require_invalid
execute unless data storage macroengine:validate out{valid:1b} run return 0

execute if entity @s[tag=macroengine.admin] run data modify storage macroengine:output result set value 1b
execute unless data storage macroengine:output {result:1b} run function macroengine:core/internal/api/perm/require_eval with storage macroengine:perm_require in
execute if data storage macroengine:output {result:1b} run return 1

playsound macroengine:perm.denied master @s ~ ~ ~ 1 1
tellraw @s ["",{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"✘ ","color":"red"},{"translate":"macroengine.msg.permission_denied","color":"red"}]
data modify storage macroengine:audit in set value {action:"perm.denied"}
data modify storage macroengine:audit in.detail set from storage macroengine:perm_require in.perm
function macroengine:systems/audit/record
return 0
