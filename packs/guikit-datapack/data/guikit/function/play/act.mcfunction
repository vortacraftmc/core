# guikit :: play/act     widget is guikit:work.w
execute if data storage guikit:work w{kind:"close"} run return run function guikit:api/close
execute if data storage guikit:work w{kind:"page"} run return run function guikit:play/act/page
execute if data storage guikit:work w{kind:"open"} run return run function guikit:play/act/open
execute if data storage guikit:work w{kind:"give"} run return run function guikit:play/act/give
execute if data storage guikit:work w{kind:"tell"} run return run function guikit:play/act/tell
execute if data storage guikit:work w{kind:"sound"} run return run function guikit:play/act/sound
execute if data storage guikit:work w{kind:"toggle"} run return run function guikit:play/act/toggle
execute if data storage guikit:work w{kind:"add"} run return run function guikit:play/act/add
execute if data storage guikit:work w{kind:"cmd"} run return run function guikit:play/act/cmd
execute if data storage guikit:work w{kind:"link"} run function guikit:play/act/link
