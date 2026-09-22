# scheduled — chest must not open on the same tick a dialog closes
execute as @a[tag=guikit.resume] at @s run function guikit:editor/resume
tag @a remove guikit.resume
