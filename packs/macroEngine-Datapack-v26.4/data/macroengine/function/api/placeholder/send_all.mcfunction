# macroengine:api/placeholder/send_all
# Like send, but every online player receives the text with the placeholders
# resolved for that player (%player% and %score:...% differ per recipient).
function macroengine:api/placeholder/parse
execute as @a run tellraw @s {"storage":"macroengine:placeholder","nbt":"out","interpret":true}
