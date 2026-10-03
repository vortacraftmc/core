scoreboard objectives add vcm_archive dummy
scoreboard players set #cmdtunnel_datapack vcm_archive 0
tag @a remove vcm_archive_cmdtunnel_datapack_seen
tellraw @s [{"text":"[ARCHIVED] ","color":"red","bold":true},{"text":"cmdTunnel approval revoked. Tick hooks stop now; effects of the load hooks stay until the world is reloaded and the data they created is removed.","color":"gray"}]
