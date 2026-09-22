# macro: $(pid) $(key) $(delta) $(max)
$scoreboard players add p$(pid)_$(key) guikit.var $(delta)
$execute if score p$(pid)_$(key) guikit.var matches $(max).. run scoreboard players set p$(pid)_$(key) guikit.var $(max)
$tellraw @s [{"text":"[GUI] ","color":"gray"},{"score":{"name":"p$(pid)_$(key)","objective":"guikit.var"},"color":"aqua"}]
