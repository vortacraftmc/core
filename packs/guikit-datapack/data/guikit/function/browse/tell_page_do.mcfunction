# macro: $(page)
$tellraw @s [{"text":"[guikit] ","color":"gold"},{"text":"Page $(page). ","color":"white"},{"text":"/trigger guikit.goto set $(page)","color":"aqua","click_event":{"action":"suggest_command","command":"/trigger guikit.goto set $(page)"}}]
