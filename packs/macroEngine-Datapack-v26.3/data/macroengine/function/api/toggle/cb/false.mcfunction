data modify storage macroengine:engine modules.cb set value 0b
tellraw @s {"text":"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"}
tellraw @s [{"translate":"macroengine.prefix","color":"#00AAAA","bold":true},{"translate":"macroengine.toggle.cb_module","color":"aqua"},{"translate":"macroengine.state.disabled","color":"red"}]
