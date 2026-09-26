function macroengine:core/disable/main

tellraw @s [{"translate":"macroengine.disable.restart"}," ",{"translate":"macroengine.disable.datapack_cmd","color":"aqua","bold":true,"italic":false,"click_event": {"action": "run_command", "command": "/datapack enable 'file/macroEngine-Datapack-1.21.2.zip'"}}]
