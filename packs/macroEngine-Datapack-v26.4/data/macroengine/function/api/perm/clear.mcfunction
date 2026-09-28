execute unless entity @s[tag=macroengine.admin] run return run tellraw @s ["",{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"text":"✘ ","color":"red"},{"text":"Permission denied.","color":"red"}]

$data remove storage macroengine:engine permissions.$(player)
$advancement revoke @a[name=$(player),limit=1] from macroengine:hidden/root