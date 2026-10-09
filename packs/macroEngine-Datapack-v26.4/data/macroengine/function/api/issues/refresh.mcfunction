# Called by packd right after it republishes the issue list.
#
# Kept as a separate function so the tool has one fixed entry point and never
# has to build a command from server output. Its body is a static announce:
# nothing here reads anything the server produced.

tellraw @a [{"text":"[macroEngine] ","color":"gold","bold":true},{"text":"issue list refreshed - ","color":"gray"},{"text":"/function macroengine:issues","color":"aqua","click_event":{"action":"suggest_command","command":"/function macroengine:issues"},"hover_event":{"action":"show_text","value":"Show the open issues"}}]
