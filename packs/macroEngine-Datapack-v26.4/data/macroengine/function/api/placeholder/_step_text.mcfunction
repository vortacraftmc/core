# macroengine:api/placeholder/_step_text [INTERNAL]
# Emit the head as {text:...} (skipped when empty), pop it, switch to name mode.
# The text is copied with `set from`, never substituted into a command or JSON
# string, so quotes, backslashes and braces in user text are harmless.
execute store result score #ph_len macroengine.tmp run data get storage macroengine:placeholder segs[0]
execute if score #ph_len macroengine.tmp matches 1.. run data modify storage macroengine:placeholder cur set value {text:""}
execute if score #ph_len macroengine.tmp matches 1.. run data modify storage macroengine:placeholder cur.text set from storage macroengine:placeholder segs[0]
execute if score #ph_len macroengine.tmp matches 1.. run data modify storage macroengine:placeholder out append from storage macroengine:placeholder cur
data remove storage macroengine:placeholder segs[0]
scoreboard players set #ph_name macroengine.tmp 1
