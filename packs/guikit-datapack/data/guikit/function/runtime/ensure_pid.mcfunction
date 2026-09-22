# guikit :: runtime/ensure_pid     stable per-player id, never reset on menu close
execute unless score @s guikit.pid matches 1.. run function guikit:runtime/assign_pid
