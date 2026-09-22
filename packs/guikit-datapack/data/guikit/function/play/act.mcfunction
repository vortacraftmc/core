# guikit :: play/act     widget is guikit:work.w
scoreboard players set #blocked guikit.tmp 0
scoreboard players set #acted guikit.tmp 1
function guikit:play/act/gate
execute if score #blocked guikit.tmp matches 1.. run return 0
execute if data storage guikit:work w{kind:"close"} run function guikit:api/close
execute if data storage guikit:work w{kind:"close"} run scoreboard players set #acted guikit.tmp 0
execute if data storage guikit:work w{kind:"page"} run function guikit:play/act/page
execute if data storage guikit:work w{kind:"open"} run function guikit:play/act/open
execute if data storage guikit:work w{kind:"give"} run function guikit:play/act/give
execute if data storage guikit:work w{kind:"tell"} run function guikit:play/act/tell
execute if data storage guikit:work w{kind:"sound"} run function guikit:play/act/sound
execute if data storage guikit:work w{kind:"toggle"} run function guikit:play/act/toggle
execute if data storage guikit:work w{kind:"add"} run function guikit:play/act/add
execute if data storage guikit:work w{kind:"cmd"} run function guikit:play/act/cmd
execute if data storage guikit:work w{kind:"link"} run function guikit:play/act/link
execute if score #acted guikit.tmp matches 1.. run function guikit:play/act/cd_arm
