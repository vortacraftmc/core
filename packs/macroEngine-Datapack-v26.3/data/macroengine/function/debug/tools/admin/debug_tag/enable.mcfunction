# macroengine:debug/tools/admin/debug_tag/enable
# Turns auto_debug_tag back ON: every admin (macroengine.admin tag) is
# granted macroengine.debug automatically each tick (legacy default).


data modify storage macroengine:engine security.auto_debug_tag set value 1b
tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"text":"✔ ","color":"green"},{"translate":"macroengine.path.auto_debug_tag","color":"white"},{"translate":"macroengine.state.enabled","color":"green"},{"translate":"macroengine.debug.tag_auto_on","color":"gray"}]
