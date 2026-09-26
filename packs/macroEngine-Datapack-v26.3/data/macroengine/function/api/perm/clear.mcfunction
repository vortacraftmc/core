execute unless entity @s[tag=macroengine.admin] run return run tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"text":"✘ ","color":"red"},{"translate":"macroengine.msg.permission_denied","color":"red"}]

$data remove storage macroengine:engine permissions.$(player)
$advancement revoke @a[name=$(player),limit=1] from macroengine:hidden/root
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.perm_clear","color":"aqua"},{"translate":"macroengine.ui.warn","color":"yellow"},{"text":"$(player)","color":"white"},{"translate":"macroengine.debug.perms_cleared","color":"#555555"}]
