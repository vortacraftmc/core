# macroengine:core/lib/fiber/internal/resume_exec [MACRO]
# INPUT: $(id), $(func)
# Fed from _fib_cur.

# Is the fiber still alive?
$execute unless data storage macroengine:engine fibers.$(id){alive:1b} run return 0

# Run via central dispatch
$data modify storage macroengine:engine _dispatch.func set value "$(func)"
function #macroengine:internal/dispatch

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.lib_fiber_resume","color":"aqua"},{"translate":"macroengine.debug.tag_run","color":"green"},{"text":"$(id)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(func)","color":"aqua"}]
