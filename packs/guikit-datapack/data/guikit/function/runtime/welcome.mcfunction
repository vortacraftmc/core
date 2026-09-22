# guikit :: runtime/welcome     once per player
tag @s add guikit.welcomed
tellraw @s [{"text":"[guikit] ","color":"gold"},{"text":"/trigger guikit.open","color":"aqua","click_event":{"action":"suggest_command","command":"/trigger guikit.open"}},{"text":" opens menus. Operators edit with /function guikit:editor/open","color":"gray"}]
