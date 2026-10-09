# macroengine:api/title/show_team_p [MACRO]
# show_p for every online member of a team. Input (macro arg): team. Storage input as show_p.
$execute as @a[team=$(team)] run function macroengine:api/title/show_p
