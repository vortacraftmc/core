# macroengine:experimental/hologram/create [MACRO]
# Spawns a floating text_display at the caller's position.
# Gated behind flags.experimental.hologram.
#
# Usage:  function macroengine:experimental/hologram/create {text:"Hello"}
# Caller: macroengine.admin tag required

execute unless entity @s[tag=macroengine.admin] run return 0
execute unless data storage macroengine:engine flags.experimental{hologram:1b} run tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.exp.hologram_disabled","color":"red"}]
execute unless data storage macroengine:engine flags.experimental{hologram:1b} run return 0

$execute positioned ~ ~1.5 ~ run summon minecraft:text_display ~ ~ ~ {Text:'{"text":"$(text)"}',billboard:"center",see_through:0b,alignment:"center",background:0,line_width:200,shadow:0b,Tags:["macroengine.experimental.hologram"]}

tellraw @s ["",{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.exp.hologram_created","color":"green"}]
