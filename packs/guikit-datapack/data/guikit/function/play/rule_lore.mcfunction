# Append click-rule lines onto guikit:w lore. Does not write them back into the menu.
execute if data storage guikit:work w{confirm:1b} run data modify storage guikit:w lore append value {text:"Click twice to confirm",color:"gold",italic:false}
execute if data storage guikit:work w{need:"vip"} run data modify storage guikit:w lore append value {text:"Requires the vip tag",color:"light_purple",italic:false}
execute if data storage guikit:work w{need:"member"} run data modify storage guikit:w lore append value {text:"Requires the member tag",color:"light_purple",italic:false}
execute if data storage guikit:work w{need:"staff"} run data modify storage guikit:w lore append value {text:"Requires the staff tag",color:"light_purple",italic:false}
execute if data storage guikit:work w{cd:60} run data modify storage guikit:w lore append value {text:"Cooldown: 3s",color:"gray",italic:false}
execute if data storage guikit:work w{cd:200} run data modify storage guikit:w lore append value {text:"Cooldown: 10s",color:"gray",italic:false}
execute if data storage guikit:work w{cd:600} run data modify storage guikit:w lore append value {text:"Cooldown: 30s",color:"gray",italic:false}
