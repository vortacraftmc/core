# ======================================================================================
# macroengine:systems/validate/safe_name
# ======================================================================================
# Checks a string WHILE IT IS STILL PLAIN DATA in storage, i.e. before it is ever
# substituted into a macro ($(...)) line.
#
# WHY: a macro argument is pasted into the command text as-is. A value such as
#        x run op @s        or        a"} run function ...
#      changes what the command means. Validating after the value has already been
#      passed as a macro argument is too late.
#
# THIS IS NOT A MACRO FUNCTION. It never substitutes the value into any command.
#
# INPUT  (storage macroengine:validate):
#   in.value    the string to check
# OUTPUT (storage macroengine:validate):
#   out.valid   1b if the value is a safe name, else 0b
#   out.error   reason (only when invalid)
# RETURN: 1 when valid, 0 when not.
#
# RULES: 1..64 characters, and none of:
#   space  "  '  \  {  }  [  ]  (  )  <  >  :  ;  ,  =  !  @  #  $  %  &  *  +  ?  /  |  ^  `  ~  §
#   newline, carriage return, tab
# i.e. letters, digits, underscore, dot and hyphen (plus non-ASCII letters) pass.
#
# USAGE:
#   data remove storage macroengine:validate in
#   data modify storage macroengine:validate in.value set value "shop.use"
#   function macroengine:systems/validate/safe_name
#   execute if data storage macroengine:validate out{valid:1b} run ...
#
# ALWAYS remove 'in' first: if the next 'set from' fails, a stale value would be checked.
# Requires the StringLib find function (macroengine:core/internal/string/util/find).
# ======================================================================================

data modify storage macroengine:validate out set value {valid:0b}
data remove storage macroengine:validate tmp

data modify storage macroengine:validate tmp.value set string storage macroengine:validate in.value
execute unless data storage macroengine:validate tmp.value run data modify storage macroengine:validate out.error set value "no value"
execute unless data storage macroengine:validate tmp.value run return 0

execute store result score #macroengine.vs_len macroengine.tmp run data get storage macroengine:validate tmp.value
execute if score #macroengine.vs_len macroengine.tmp matches ..0 run data modify storage macroengine:validate out.error set value "empty"
execute if score #macroengine.vs_len macroengine.tmp matches ..0 run return 0
execute if score #macroengine.vs_len macroengine.tmp matches 65.. run data modify storage macroengine:validate out.error set value "too long (max 64)"
execute if score #macroengine.vs_len macroengine.tmp matches 65.. run return 0

data modify storage macroengine:core/internal/string/input find.String set from storage macroengine:validate tmp.value
data modify storage macroengine:core/internal/string/input find.n set value 1
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
function macroengine:core/internal/systems/validate/scan_chars

execute if data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:validate out.error set value "contains a disallowed character"
execute if data storage macroengine:validate tmp{bad:1b} run return 0

data modify storage macroengine:validate out.valid set value 1b
data remove storage macroengine:validate tmp
return 1
