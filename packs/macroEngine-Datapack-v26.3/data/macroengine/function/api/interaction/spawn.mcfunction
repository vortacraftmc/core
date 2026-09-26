$summon minecraft:interaction ~ ~ ~ {width:$(width), height:$(height), response:$(response), Tags:["macroengine.interaction","macroengine.ia_new"]}

$tag @e[type=minecraft:interaction,tag=macroengine.ia_new,limit=1,sort=nearest] add $(tag)
tag @e[tag=macroengine.ia_new] remove macroengine.ia_new

# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.interaction_spawn","color":"aqua"},{"text":"✔ ","color":"green"},{"text":"$(tag)","color":"white"},{"translate":"macroengine.debug.spawned","color":"#555555"}]
