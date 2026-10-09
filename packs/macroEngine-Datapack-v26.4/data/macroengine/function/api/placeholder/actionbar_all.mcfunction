# macroengine:api/placeholder/actionbar_all
# Like actionbar, but every online player sees the text resolved for themselves.
function macroengine:api/placeholder/parse
execute as @a run title @s actionbar {"storage":"macroengine:placeholder","nbt":"out","interpret":true}
