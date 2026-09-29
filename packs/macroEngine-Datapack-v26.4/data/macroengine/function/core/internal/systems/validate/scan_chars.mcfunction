# macroengine:core/internal/systems/validate/scan_chars  [INTERNAL]
# Called by macroengine:systems/validate/safe_name. Expects find.String / find.n to be set.
# Sets macroengine:validate tmp.bad = 1b if any forbidden character is present.
#
# Every character is a STATIC line on purpose. Passing the character as a macro
# argument ("$(char)" inside a quoted string) breaks for " and \ : the substituted
# text becomes """ or "\" and the line fails to parse, so that check silently never runs.

# space
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value " "
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# "
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "\""
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# '
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "'"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# \
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "\\"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# {
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "{"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# }
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "}"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# [
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "["
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# ]
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "]"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# (
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "("
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# )
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value ")"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# <
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "<"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# >
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value ">"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# :
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value ":"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# ;
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value ";"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# ,
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value ","
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# =
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "="
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# !
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "!"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# @
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "@"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# #
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "#"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# $
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "$"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# %
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "%"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# &
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "&"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# *
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "*"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# +
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "+"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# ?
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "?"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# /
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "/"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# |
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "|"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# ^
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "^"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# `
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "`"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# ~
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "~"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# §
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "§"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# newline
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "\n"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# CR
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "\r"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
# tab
execute unless data storage macroengine:validate tmp{bad:1b} run data modify storage macroengine:core/internal/string/input find.Find set value "\t"
scoreboard players set #macroengine.vs_hit macroengine.tmp 0
execute unless data storage macroengine:validate tmp{bad:1b} store success score #macroengine.vs_hit macroengine.tmp run function macroengine:core/internal/string/util/find
execute if score #macroengine.vs_hit macroengine.tmp matches 1 run data modify storage macroengine:validate tmp.bad set value 1b
