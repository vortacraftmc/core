execute unless data storage guikit:work w.url run scoreboard players set #acted guikit.tmp 0
execute unless data storage guikit:work w.url run return run tellraw @s {"text":"[GUI] This button has no link.","color":"red"}
function guikit:internal/btn/url with storage guikit:work w
function guikit:api/close
