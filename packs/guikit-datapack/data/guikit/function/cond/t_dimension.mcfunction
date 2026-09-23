# macro: $(dim)
# Passes when the player currently is in that dimension (minecraft:overworld, minecraft:the_nether,
# minecraft:the_end, or any modded/custom dimension id). `at @s` moves the execution context to the
# player, so the check is correct no matter where the caller was running.
$execute at @s if dimension $(dim) run scoreboard players set #cond guikit.tmp 1
