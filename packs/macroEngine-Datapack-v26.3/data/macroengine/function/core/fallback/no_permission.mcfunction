# macroengine:core/fallback/no_permission
# Called when executor's macroengine.perm_level < security.cmd_min_level (or sandbox threshold).

data modify storage macroengine:engine _log_add_tmp.message set value "[Fallback] no_permission — macroengine.perm_level below required threshold"
data modify storage macroengine:engine _log_add_tmp.level set value "WARN"
data modify storage macroengine:engine _log_add_tmp.color set value "yellow"
execute if score #macroengine.log_level macroengine.log_level matches 2.. run function macroengine:systems/log/add with storage macroengine:engine _log_add_tmp
data remove storage macroengine:engine _log_add_tmp.message
data remove storage macroengine:engine _log_add_tmp.level
data remove storage macroengine:engine _log_add_tmp.color

# Notify caller
tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"text":"✘ ","color":"red"},{"translate":"macroengine.msg.perm_level_pre","color":"red"},{"translate":"macroengine.fmt.perm_level_name","color":"aqua"},{"translate":"macroengine.msg.perm_level_post","color":"red"}]

# Notify debug admins
# # tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.debug.no_perm_tag","color":"yellow","bold":true},{"selector":"@s","color":"gold"},{"translate":"macroengine.debug.perm_below","color":"yellow"}]

data modify storage macroengine:output fallback set value {triggered:1b,reason:"no_permission"}
return 0
