# guikit :: play/last_sweep     walks every pid slot in guikit:mem last and drops entries that
# point at the menu currently being deleted (storage guikit:work gone / guikit:ctx gone).
# One slot per recursion step; the loop stops when #mi passes the highest pid ever handed out.
execute unless score #mi guikit.tmp <= #mn guikit.tmp run return 0
execute store result storage guikit:ctx pid int 1 run scoreboard players get #mi guikit.tmp
function guikit:play/last_sweep_one with storage guikit:ctx
scoreboard players add #mi guikit.tmp 1
function guikit:play/last_sweep
