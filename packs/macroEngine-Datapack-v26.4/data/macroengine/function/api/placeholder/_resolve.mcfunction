# macroengine:api/placeholder/_resolve [INTERNAL]
# segs[0] is a name enclosed by two '%'. Appends exactly one result to out:
#   ""           -> a literal '%'   (the %% escape)
#   score:<obj>  -> scoreboard value of the executor
#   registered   -> the stored component
#   otherwise    -> the original "%name%" text, unchanged
# The name is validated (no quote/backslash, none of the characters in the
# deny_name table) before it is used as a macro argument.
data remove storage macroengine:placeholder cur
data modify storage macroengine:placeholder name set from storage macroengine:placeholder segs[0]
execute store result score #ph_len macroengine.tmp run data get storage macroengine:placeholder name
execute if score #ph_len macroengine.tmp matches 0 run data modify storage macroengine:placeholder cur set value {text:"%"}

# score:<objective>
execute if score #ph_len macroengine.tmp matches 7.. unless data storage macroengine:placeholder cur run function macroengine:api/placeholder/_try_score

# registered placeholder
execute unless data storage macroengine:placeholder cur run function macroengine:api/placeholder/_try_registered

execute if data storage macroengine:placeholder cur run data modify storage macroengine:placeholder out append from storage macroengine:placeholder cur
execute if data storage macroengine:placeholder cur run return 1

# unknown: keep "%name%" exactly as written
data modify storage macroengine:placeholder cur set value {text:"%"}
data modify storage macroengine:placeholder out append from storage macroengine:placeholder cur
data modify storage macroengine:placeholder cur set value {text:""}
data modify storage macroengine:placeholder cur.text set from storage macroengine:placeholder name
data modify storage macroengine:placeholder out append from storage macroengine:placeholder cur
data modify storage macroengine:placeholder cur set value {text:"%"}
data modify storage macroengine:placeholder out append from storage macroengine:placeholder cur
data remove storage macroengine:placeholder cur
