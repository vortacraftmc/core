scoreboard objectives add vcm_archive dummy
scoreboard players set #leftclickdetection vcm_archive 0
tag @a remove vcm_archive_leftclickdetection_seen
tellraw @s [{"text":"[ARCHIVED] ","color":"red","bold":true},{"text":"LeftClickDetection approval revoked. Tick hooks stop now; effects of the load hooks stay until the world is reloaded and the data they created is removed.","color":"gray"}]
