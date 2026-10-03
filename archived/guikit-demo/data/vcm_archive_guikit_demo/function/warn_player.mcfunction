tag @s add vcm_archive_guikit_demo_seen
tellraw @s [{"text":"[ARCHIVED] ","color":"red","bold":true},{"text":"guikit-demo","color":"gold","bold":true},{"text":" is a frozen, reference-only datapack (archived 2026-10-03).","color":"gray"}]
tellraw @s [{"text":"No feature updates. Do not run it on a live server without reviewing its code first.","color":"gray"}]
tellraw @s [{"text":"This pack has no load/tick hooks, so it cannot be held back automatically; its functions can still be called by hand. Approving only silences this notice: ","color":"red"},{"text":"/function vcm_archive_guikit_demo:confirm","color":"yellow"}]
tellraw @s [{"text":"Read the risks first: ","color":"gray"},{"text":"/function vcm_archive_guikit_demo:info","color":"yellow"},{"text":"   (operator permission needed for both commands)","color":"dark_gray"}]
