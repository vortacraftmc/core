# default 1 second. A stored 0 / 60 / 100 overrides it. Editor chest sets 0 itself.
scoreboard players set @s guikit.rfiv 20
execute if data storage guikit:work menu{refresh:0} run scoreboard players set @s guikit.rfiv 0
execute if data storage guikit:work menu{refresh:60} run scoreboard players set @s guikit.rfiv 60
execute if data storage guikit:work menu{refresh:100} run scoreboard players set @s guikit.rfiv 100
