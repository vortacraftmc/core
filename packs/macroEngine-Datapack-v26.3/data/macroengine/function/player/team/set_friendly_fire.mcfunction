$team modify $(team) friendlyFire $(value)
$data modify storage macroengine:engine teams.$(team).friendly_fire set value "$(value)"
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.team_set_friendly_fire","color":"aqua"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(team)","color":"aqua"}]
