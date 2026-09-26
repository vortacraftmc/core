execute if entity @s[tag=macroengine.admin] run function macroengine:core/internal/api/perm/trigger/exec with storage macroengine:engine _ptd_current

$execute unless entity @s[tag=macroengine.admin] if entity @s[tag=perm.$(perm)] run function macroengine:core/internal/api/perm/trigger/exec with storage macroengine:engine _ptd_current

$execute unless entity @s[tag=macroengine.admin] unless entity @s[tag=perm.$(perm)] run tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"text":"✘ ","color":"red"},{"text":"$(perm)","color":"yellow"},{"translate":"macroengine.msg.no_perm","color":"red"}]
