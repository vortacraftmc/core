$execute store result storage macroengine:engine config.$(key) int 1 run scoreboard players set $cfg_tmp macroengine.tmp $(value)
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.config_set_int","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(key)","color":"aqua"}]
