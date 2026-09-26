# macroengine:api/interaction/internal/bind_attack_do [MACRO] [INTERNAL]
# Called by bind_attack with storage macroengine:input {} to do the actual append.
# INPUT: $(tag), $(func)
$data modify storage macroengine:engine interaction_binds.attack append value {tag:"$(tag)", func:"$(func)"}
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.interaction_bind_attack","color":"aqua"},{"text":"✔ ","color":"green"},{"text":"$(tag)","color":"white"},{"translate":"macroengine.arrow","color":"#555555"},{"text":"$(func)","color":"aqua"}]
