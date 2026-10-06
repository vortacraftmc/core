# guikit :: play/close_trigger    as player  —  /trigger guikit.close
# Closes the player's own open menu immediately (no waiting for the timeout, no operator needed).
# api/close only touches the cart whose uid matches this player, so nobody else's menu is affected.
scoreboard players set @s guikit.close 0
scoreboard players enable @s guikit.close
execute unless score @s guikit.uid matches 1.. run tellraw @s {"text":"[guikit] You have no open menu.","color":"red"}
execute unless score @s guikit.uid matches 1.. run return 0
function guikit:api/close
