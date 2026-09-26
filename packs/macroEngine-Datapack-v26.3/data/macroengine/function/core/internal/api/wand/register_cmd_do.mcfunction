# macroengine:api/wand/internal/register_cmd_do [MACRO] [INTERNAL]
# Called by wand/register_cmd with storage macroengine:input {} to do the actual append.
# INPUT: $(tag), $(cmd)
$data modify storage macroengine:engine wand_binds append value {tag:"$(tag)", cmd:"$(cmd)"}
# # $tellraw @a[tag=macroengine.debug] ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.path.wand_register_cmd","color":"aqua"},{"text":"✔ ","color":"green"},{"text":"$(tag)","color":"white"},{"translate":"macroengine.fmt.arrow_cmd","color":"#555555"}]
