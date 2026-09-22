# guikit :: internal/reset_cd     as player     (reward of the advancement guikit:interact_cart)
# Restarts the MENU TIMEOUT (`guikit.timer`, the countdown that closes an idle menu) when the player
# interacts with (right-clicks) a guikit cart. NOT the cooldown scoreboard `guikit.cd`, despite the name.
# It restores the value the menu was opened with (`guikit.tmax`, set by api/open). Clicking widgets inside
# the open GUI does NOT reset the timer any more.
# The advancement is granted only once, so it has to be revoked here or it could never fire again.
advancement revoke @s only guikit:interact_cart
# A non-owner click must not refresh this player's timeout, and must not count as the owner's.
scoreboard players set #own guikit.tmp 0
scoreboard players set #uid guikit.tmp 0
scoreboard players operation #uid guikit.tmp = @s guikit.uid
execute as @e[type=#guikit:container,tag=guikit.cart,distance=..8] if score @s guikit.uid = #uid guikit.tmp run scoreboard players set #own guikit.tmp 1
execute as @e[type=#guikit:container,tag=guikit.cart,distance=..8] unless score @s guikit.uid = #uid guikit.tmp at @s run function guikit:internal/guard/force_show
execute if score #own guikit.tmp matches 0 run return run function guikit:internal/guard/reject
execute if score @s guikit.uid matches 1.. if score @s guikit.tmax matches 1.. run scoreboard players operation @s guikit.timer = @s guikit.tmax
