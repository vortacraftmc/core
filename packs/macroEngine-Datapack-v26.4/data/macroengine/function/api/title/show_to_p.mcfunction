# macroengine:api/title/show_to_p [MACRO]
# show_p for a named player. Input (macro arg): player. Storage input as show_p.
$execute as @a[name=$(player),limit=1] run function macroengine:api/title/show_p
