# No permission gate — runs $(cmd) unconditionally, admins are only notified.

tellraw @a[tag=macroengine.admin] [{"selector":"@s","color":"gold"},{"text":" - command executed","color":"yellow"}]

$$(cmd)
