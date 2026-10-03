tag @s add vcm_archive_quickshare_seen
tellraw @s [{"text":"[ARCHIVED] ","color":"red","bold":true},{"text":"QuickShare","color":"gold","bold":true},{"text":" is a frozen, reference-only datapack (archived 2026-10-03).","color":"gray"}]
tellraw @s [{"text":"No feature updates. Do not run it on a live server without reviewing its code first.","color":"gray"}]
tellraw @s [{"text":"This pack is INACTIVE until a server operator approves loading it: ","color":"red"},{"text":"/function vcm_archive_quickshare:confirm","color":"yellow"}]
tellraw @s [{"text":"Read the risks first: ","color":"gray"},{"text":"/function vcm_archive_quickshare:info","color":"yellow"},{"text":"   (operator permission needed for both commands)","color":"dark_gray"}]
