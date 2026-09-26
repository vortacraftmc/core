$team add $(team)
$data modify storage macroengine:engine teams.$(team) set value {color:"white",friendly_fire:"true",see_friendly_invisibles:"false"}
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.team_create","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(team)","color":"aqua"}]
