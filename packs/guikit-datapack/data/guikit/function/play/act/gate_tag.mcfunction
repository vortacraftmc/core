# Literal tag checks only. The need string is never used as a selector.
execute if data storage guikit:work w{need:"vip"} unless entity @s[tag=vip] run function guikit:play/act/deny_vip
execute if score #blocked guikit.tmp matches 1.. run return 0
execute if data storage guikit:work w{need:"member"} unless entity @s[tag=member] run function guikit:play/act/deny_member
execute if score #blocked guikit.tmp matches 1.. run return 0
execute if data storage guikit:work w{need:"staff"} unless entity @s[tag=staff] run function guikit:play/act/deny_staff
