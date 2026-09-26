# macroengine:core/lib/fiber/internal/kill_exec [MACRO]
# INPUT: $(id)

$execute unless data storage macroengine:engine fibers.$(id) run return 0

$data remove storage macroengine:engine fibers.$(id).alive
$data remove storage macroengine:engine fibers.$(id).resume

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_fiber_kill","color":"aqua"},{"translate":"macroengine.debug.tag_killed","color":"#FF5555"},{"text":"$(id)","color":"white"}]
