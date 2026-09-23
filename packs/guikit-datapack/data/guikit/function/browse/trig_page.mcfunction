# /trigger guikit.goto set <1-32>. Bare trigger is page 1.
# guikit.page is the open menu's page and must not be used here.
scoreboard players operation #want guikit.tmp = @s guikit.goto
scoreboard players set @s guikit.goto 0
scoreboard players enable @s guikit.goto
execute unless score #want guikit.tmp matches 1..32 run function guikit:browse/usage_page
execute unless score #want guikit.tmp matches 1..32 run scoreboard players set #want guikit.tmp 1
scoreboard players remove #want guikit.tmp 1
scoreboard players operation @s guikit.bpage = #want guikit.tmp
scoreboard players set #keep guikit.tmp 1
function guikit:browse/show
function guikit:browse/tell_page
