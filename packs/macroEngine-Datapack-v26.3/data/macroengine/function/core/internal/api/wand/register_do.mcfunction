# macroengine:api/wand/internal/register_do [MACRO] [INTERNAL]
# Called by wand/register with storage macroengine:input {} to do the actual append.
# INPUT: $(tag), $(func), $(cmd)
$data modify storage macroengine:engine wand_binds append value {tag:"$(tag)", func:"$(func)", cmd:"$(cmd)"}
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.wand_register","color":"aqua"},{"text":"✔ ","color":"green"},{"text":"$(tag)","color":"white"}]
