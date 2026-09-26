$team modify $(team) color $(color)
$data modify storage macroengine:engine teams.$(team).color set value "$(color)"
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.team_set_color","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(team)","color":"aqua"}]
