#!/usr/bin/env python3
"""Generates macroengine:core/internal/text/* (in-house string utilities)."""
import os, sys

PACK = sys.argv[1]
BASE = os.path.join(PACK, "data/macroengine/function/core/internal/text")
os.makedirs(BASE, exist_ok=True)
T = "macroengine:text"
M = "macroengine:text_map"
S = "macroengine.tmp"
NS = "macroengine:core/internal/text"


def w(name, text):
    p = os.path.join(BASE, name + ".mcfunction")
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8") as f:
        f.write(text.strip("\n") + "\n")


# ---------------------------------------------------------------- primitives
w("_cut", f"""
# {NS}/_cut [MACRO]
# INPUT $(a) $(b): win = substring [a, b) of storage {T} s. Bounds must be valid.
$data modify storage {T} win set string storage {T} s $(a) $(b)
""")

w("_cut_ab", f"""
# {NS}/_cut_ab
# win = substring [#tx_a, #tx_b) of storage {T} s. An empty range yields "" directly.
execute if score #tx_a {S} = #tx_b {S} run data modify storage {T} win set value ""
execute if score #tx_a {S} = #tx_b {S} run return 1
execute store result storage {T} arg.a int 1 run scoreboard players get #tx_a {S}
execute store result storage {T} arg.b int 1 run scoreboard players get #tx_b {S}
function {NS}/_cut with storage {T} arg
return 1
""")

w("reset", f"""
# {NS}/reset
# Drops the working buffers of the text module. Callers copy their result out first.
data remove storage {T} s
data remove storage {T} needle
data remove storage {T} rep
data remove storage {T} n
data remove storage {T} idx
data remove storage {T} pc
data remove storage {T} nl
data remove storage {T} cl
data remove storage {T} win
data remove storage {T} cmp
data remove storage {T} arg
data remove storage {T} jarg
data remove storage {T} jout
data remove storage {T} mp
data remove storage {T} ch
data remove storage {T} r
data remove storage {T} isd
""")

# ---------------------------------------------------------------- find
w("find", f"""
# {NS}/find
# Positions of non-overlapping occurrences of a needle in a string.
# INPUT  {T}: s (string), needle (string), n (int, optional)
#          n = 0 all, n > 0 the first n, n < 0 the last |n|
# OUTPUT {T}: idx (list of start indices, ascending)
# RETURN number of occurrences in idx. An empty needle matches nothing.
execute unless data storage {T} n run data modify storage {T} n set value 0
data modify storage {T} idx set value []
scoreboard players set #tx_hits {S} 0
execute store result score #tx_len {S} run data get storage {T} s
execute store result score #tx_nlen {S} run data get storage {T} needle
execute store result score #tx_max {S} run data get storage {T} n
execute if score #tx_nlen {S} matches 0 run return 0
scoreboard players operation #tx_last {S} = #tx_len {S}
scoreboard players operation #tx_last {S} -= #tx_nlen {S}
execute if score #tx_last {S} matches ..-1 run return 0
scoreboard players set #tx_cap {S} 0
execute if score #tx_max {S} matches 1.. run scoreboard players operation #tx_cap {S} = #tx_max {S}
scoreboard players set #tx_i {S} 0
function {NS}/find_loop
execute if score #tx_max {S} matches ..-1 run function {NS}/find_trim
return run scoreboard players get #tx_hits {S}
""")

w("find_loop", f"""
# {NS}/find_loop [INTERNAL] one window comparison per call
scoreboard players operation #tx_a {S} = #tx_i {S}
scoreboard players operation #tx_b {S} = #tx_i {S}
scoreboard players operation #tx_b {S} += #tx_nlen {S}
function {NS}/_cut_ab
data modify storage {T} cmp set from storage {T} win
execute store success score #tx_diff {S} run data modify storage {T} cmp set from storage {T} needle
execute if score #tx_diff {S} matches 0 run function {NS}/find_hit
execute if score #tx_diff {S} matches 1 run scoreboard players add #tx_i {S} 1
execute if score #tx_cap {S} matches 1.. if score #tx_hits {S} >= #tx_cap {S} run return 0
execute if score #tx_i {S} <= #tx_last {S} run function {NS}/find_loop
""")

w("find_hit", f"""
# {NS}/find_hit [INTERNAL] record a match at #tx_i and skip past it
data modify storage {T} idx append value 0
execute store result storage {T} idx[-1] int 1 run scoreboard players get #tx_i {S}
scoreboard players add #tx_hits {S} 1
scoreboard players operation #tx_i {S} += #tx_nlen {S}
""")

w("find_trim", f"""
# {NS}/find_trim [INTERNAL] keep only the last |n| matches
scoreboard players set #tx_m1 {S} -1
scoreboard players operation #tx_drop {S} = #tx_max {S}
scoreboard players operation #tx_drop {S} *= #tx_m1 {S}
scoreboard players operation #tx_drop {S} -= #tx_hits {S}
scoreboard players operation #tx_drop {S} *= #tx_m1 {S}
execute if score #tx_drop {S} matches 1.. run function {NS}/find_drop
""")

w("find_drop", f"""
# {NS}/find_drop [INTERNAL] pops the oldest match #tx_drop times
data remove storage {T} idx[0]
scoreboard players remove #tx_drop {S} 1
scoreboard players remove #tx_hits {S} 1
execute if score #tx_drop {S} matches 1.. run function {NS}/find_drop
""")

w("count", f"""
# {NS}/count
# INPUT {T}: s, needle.  RETURN number of non-overlapping occurrences.
data modify storage {T} n set value 0
return run function {NS}/find
""")

w("has", f"""
# {NS}/has
# INPUT {T}: s, needle.  RETURN 1 if s contains needle, else 0.
data modify storage {T} n set value 1
return run function {NS}/find
""")

w("safe", f"""
# {NS}/safe
# RETURN 1 when {T} s contains neither a double quote nor a backslash, else 0.
# Anything that is rebuilt into a macro string literal must pass this first.
# Walks the string one character at a time without macros; touches only sf, sc, sq.
data modify storage {T} sf set from storage {T} s
execute store result score #tx_sn {S} run data get storage {T} sf
execute if score #tx_sn {S} matches 0 run return 1
return run function {NS}/safe_loop
""")

w("safe_loop", f"""
# {NS}/safe_loop [INTERNAL]
# Pops the first character of sf and rejects a double quote or a backslash.
data modify storage {T} sc set string storage {T} sf 0 1
data modify storage {T} sf set string storage {T} sf 1
data modify storage {T} sq set from storage {T} sc
execute store success score #tx_qq {S} run data modify storage {T} sq set value '"'
execute if score #tx_qq {S} matches 0 run return 0
data modify storage {T} sq set from storage {T} sc
execute store success score #tx_qq {S} run data modify storage {T} sq set value '\\\\'
execute if score #tx_qq {S} matches 0 run return 0
scoreboard players remove #tx_sn {S} 1
execute if score #tx_sn {S} matches 1.. run return run function {NS}/safe_loop
return 1
""")

# ---------------------------------------------------------------- join
w("_join16", "\n".join([
    f"# {NS}/_join16 [MACRO]",
    "# INPUT $(p0)..$(p15): up to 16 quote-free strings. Joined into storage " + T + " jout.",
    "$data modify storage " + T + ' jout set value "' + "".join(f"$(p{i})" for i in range(16)) + '"',
]))

take = []
for i in range(16):
    take.append(f"execute if data storage {T} pc[0] run data modify storage {T} jarg.p{i} set from storage {T} pc[0]")
    take.append(f"data remove storage {T} pc[0]")
w("join_take", f"""
# {NS}/join_take [INTERNAL] joins the next 16 entries of pc into one entry of nl
data modify storage {T} jarg set value {{{",".join(f'p{i}:""' for i in range(16))}}}
""" + "\n".join(take) + f"""
function {NS}/_join16 with storage {T} jarg
data modify storage {T} nl append from storage {T} jout
execute if data storage {T} pc[0] run function {NS}/join_take
""")

w("join_round", f"""
# {NS}/join_round [INTERNAL] one reduction round, repeats until one entry is left
data modify storage {T} nl set value []
function {NS}/join_take
data modify storage {T} pc set from storage {T} nl
execute if data storage {T} pc[1] run function {NS}/join_round
""")

w("join", f"""
# {NS}/join
# Concatenates the strings in {T} pc into {T} out.
# Every entry must already be free of double quotes and backslashes (see safe).
execute unless data storage {T} pc[0] run data modify storage {T} out set value ""
execute unless data storage {T} pc[0] run return 1
execute unless data storage {T} pc[1] run data modify storage {T} out set from storage {T} pc[0]
execute unless data storage {T} pc[1] run return 1
function {NS}/join_round
data modify storage {T} out set from storage {T} pc[0]
return 1
""")

# ---------------------------------------------------------------- concat
w("concat", f"""
# {NS}/concat
# INPUT  {T}: list (list of strings; numbers are converted)
# OUTPUT {T}: out (string)   on failure: err, out unset
# RETURN 1 on success, 0 on failure.
data remove storage {T} err
data remove storage {T} out
data modify storage {T} pc set value []
data remove storage {T} cl
data modify storage {T} cl set from storage {T} list
execute store result score #tx_r {S} run function {NS}/concat_loop
execute if data storage {T} err run return 0
function {NS}/join
return 1
""")

w("concat_loop", f"""
# {NS}/concat_loop [INTERNAL]
execute unless data storage {T} cl[0] run return 1
data modify storage {T} s set string storage {T} cl[0]
data remove storage {T} cl[0]
execute store result score #tx_ok {S} run function {NS}/safe
execute if score #tx_ok {S} matches 0 run data modify storage {T} err set value "concat: an element contains a quote or backslash"
execute if score #tx_ok {S} matches 0 run return 0
data modify storage {T} pc append from storage {T} s
return run function {NS}/concat_loop
""")

# ---------------------------------------------------------------- replace
w("replace", f"""
# {NS}/replace
# INPUT  {T}: s, needle, rep (strings), n (int, optional: 0 all, +n first n, -n last n)
# OUTPUT {T}: out (string)   on failure: err, out unset
# RETURN number of replacements. s and rep must not contain a quote or backslash.
data remove storage {T} err
data remove storage {T} out
execute unless data storage {T} n run data modify storage {T} n set value 0
data modify storage {T} r set value {{}}
data modify storage {T} r.s set from storage {T} s
data modify storage {T} r.needle set from storage {T} needle
data modify storage {T} r.rep set from storage {T} rep
data modify storage {T} r.n set from storage {T} n
execute store result score #tx_ok {S} run function {NS}/safe
execute if score #tx_ok {S} matches 0 run data modify storage {T} err set value "replace: the string contains a quote or backslash"
execute if score #tx_ok {S} matches 0 run return 0
data modify storage {T} s set from storage {T} r.rep
execute store result score #tx_ok {S} run function {NS}/safe
data modify storage {T} s set from storage {T} r.s
execute if score #tx_ok {S} matches 0 run data modify storage {T} err set value "replace: the replacement contains a quote or backslash"
execute if score #tx_ok {S} matches 0 run return 0
data modify storage {T} needle set from storage {T} r.needle
data modify storage {T} n set from storage {T} r.n
execute store result score #tx_total {S} run function {NS}/find
execute if score #tx_total {S} matches 0 run data modify storage {T} out set from storage {T} r.s
execute if score #tx_total {S} matches 0 run return 0
data modify storage {T} pc set value []
scoreboard players set #tx_pos {S} 0
function {NS}/replace_loop
execute store result score #tx_len {S} run data get storage {T} s
scoreboard players operation #tx_a {S} = #tx_pos {S}
scoreboard players operation #tx_b {S} = #tx_len {S}
function {NS}/_cut_ab
data modify storage {T} pc append from storage {T} win
function {NS}/join
return run scoreboard players get #tx_total {S}
""")

w("replace_loop", f"""
# {NS}/replace_loop [INTERNAL] emits "text before match" + replacement per match
execute unless data storage {T} idx[0] run return 0
execute store result score #tx_k {S} run data get storage {T} idx[0]
scoreboard players operation #tx_a {S} = #tx_pos {S}
scoreboard players operation #tx_b {S} = #tx_k {S}
function {NS}/_cut_ab
data modify storage {T} pc append from storage {T} win
data modify storage {T} pc append from storage {T} r.rep
scoreboard players operation #tx_pos {S} = #tx_k {S}
scoreboard players operation #tx_pos {S} += #tx_nlen {S}
data remove storage {T} idx[0]
function {NS}/replace_loop
""")

# ---------------------------------------------------------------- insert
w("insert", f"""
# {NS}/insert
# INPUT  {T}: s, ins (strings), at (int, 0..length)
# OUTPUT {T}: out (string)   on failure: err, out unset
# RETURN 1 on success, 0 on failure. s and ins must not contain a quote or backslash.
data remove storage {T} err
data remove storage {T} out
execute unless data storage {T} at run data modify storage {T} at set value 0
execute store result score #tx_len {S} run data get storage {T} s
execute store result score #tx_at {S} run data get storage {T} at
execute if score #tx_at {S} matches ..-1 run data modify storage {T} err set value "insert: index out of range"
execute if score #tx_at {S} > #tx_len {S} run data modify storage {T} err set value "insert: index out of range"
execute if data storage {T} err run return 0
data modify storage {T} r set value {{}}
data modify storage {T} r.s set from storage {T} s
data modify storage {T} r.ins set from storage {T} ins
execute store result score #tx_ok {S} run function {NS}/safe
execute if score #tx_ok {S} matches 0 run data modify storage {T} err set value "insert: the string contains a quote or backslash"
execute if score #tx_ok {S} matches 0 run return 0
data modify storage {T} s set from storage {T} r.ins
execute store result score #tx_ok {S} run function {NS}/safe
data modify storage {T} s set from storage {T} r.s
execute store result score #tx_len {S} run data get storage {T} s
execute if score #tx_ok {S} matches 0 run data modify storage {T} err set value "insert: the inserted text contains a quote or backslash"
execute if score #tx_ok {S} matches 0 run return 0
data modify storage {T} pc set value []
scoreboard players set #tx_a {S} 0
scoreboard players operation #tx_b {S} = #tx_at {S}
function {NS}/_cut_ab
data modify storage {T} pc append from storage {T} win
data modify storage {T} pc append from storage {T} r.ins
scoreboard players operation #tx_a {S} = #tx_at {S}
scoreboard players operation #tx_b {S} = #tx_len {S}
function {NS}/_cut_ab
data modify storage {T} pc append from storage {T} win
function {NS}/join
return 1
""")

# ---------------------------------------------------------------- split
w("split", f"""
# {NS}/split
# INPUT  {T}: s, sep (strings; "" splits into characters),
#          n (int, optional: 0 all, +n first n separators, -n last n separators),
#          keep_empty (byte, optional, default 0b)
# OUTPUT {T}: out (list of strings)
# RETURN number of entries in out. Splitting "" yields [""].
data remove storage {T} err
data modify storage {T} out set value []
execute unless data storage {T} n run data modify storage {T} n set value 0
execute store result score #tx_keep {S} run data get storage {T} keep_empty
execute store result score #tx_len {S} run data get storage {T} s
execute if score #tx_len {S} matches 0 run data modify storage {T} out set value [""]
execute if score #tx_len {S} matches 0 run return 1
execute store result score #tx_slen {S} run data get storage {T} sep
execute if score #tx_slen {S} matches 0 run scoreboard players set #tx_i {S} 0
execute if score #tx_slen {S} matches 0 run function {NS}/split_chars
execute if score #tx_slen {S} matches 0 run return run data get storage {T} out
data modify storage {T} needle set from storage {T} sep
execute store result score #tx_total {S} run function {NS}/find
scoreboard players set #tx_pos {S} 0
function {NS}/split_loop
scoreboard players operation #tx_a {S} = #tx_pos {S}
scoreboard players operation #tx_b {S} = #tx_len {S}
function {NS}/_cut_ab
function {NS}/split_emit
return run data get storage {T} out
""")

w("split_chars", f"""
# {NS}/split_chars [INTERNAL] one entry per character
scoreboard players operation #tx_a {S} = #tx_i {S}
scoreboard players operation #tx_b {S} = #tx_i {S}
scoreboard players add #tx_b {S} 1
function {NS}/_cut_ab
data modify storage {T} out append from storage {T} win
scoreboard players add #tx_i {S} 1
execute if score #tx_i {S} < #tx_len {S} run function {NS}/split_chars
""")

w("split_loop", f"""
# {NS}/split_loop [INTERNAL] one segment per separator match
execute unless data storage {T} idx[0] run return 0
execute store result score #tx_k {S} run data get storage {T} idx[0]
scoreboard players operation #tx_a {S} = #tx_pos {S}
scoreboard players operation #tx_b {S} = #tx_k {S}
function {NS}/_cut_ab
function {NS}/split_emit
scoreboard players operation #tx_pos {S} = #tx_k {S}
scoreboard players operation #tx_pos {S} += #tx_slen {S}
data remove storage {T} idx[0]
function {NS}/split_loop
""")

w("split_emit", f"""
# {NS}/split_emit [INTERNAL] appends win to out unless it is empty and empties are dropped
execute store result score #tx_wl {S} run data get storage {T} win
execute if score #tx_wl {S} matches 1.. run data modify storage {T} out append from storage {T} win
execute if score #tx_wl {S} matches 0 if score #tx_keep {S} matches 1 run data modify storage {T} out append from storage {T} win
""")

# ---------------------------------------------------------------- case mapping
for name, tbl, full in (("lower", "lower", False), ("upper", "upper", False),
                        ("lower_full", "lower_full", True), ("upper_full", "upper_full", True)):
    pre = f"execute unless data storage {M} {{full:1b}} run function {NS}/load_full\n" if full else ""
    scope = "the whole BMP (simple one-to-one mappings)" if full else "ASCII letters only"
    w(name, f"""
# {NS}/{name}
# INPUT  {T}: s    OUTPUT {T}: out   (or err)   RETURN 1 on success, 0 on failure
# Case mapping for {scope}.
# s must not contain a quote or backslash.
{pre}data modify storage {T} tbl set value "{tbl}"
return run function {NS}/case
""")

w("case", f"""
# {NS}/case [INTERNAL] maps every character of s through table {T} tbl
data remove storage {T} err
data remove storage {T} out
execute store result score #tx_len {S} run data get storage {T} s
execute if score #tx_len {S} matches 0 run data modify storage {T} out set value ""
execute if score #tx_len {S} matches 0 run return 1
execute store result score #tx_ok {S} run function {NS}/safe
execute if score #tx_ok {S} matches 0 run data modify storage {T} err set value "case: the string contains a quote or backslash"
execute if score #tx_ok {S} matches 0 run return 0
data modify storage {T} pc set value []
scoreboard players set #tx_i {S} 0
function {NS}/case_loop
function {NS}/join
return 1
""")

w("case_loop", f"""
# {NS}/case_loop [INTERNAL] one character per call
scoreboard players operation #tx_a {S} = #tx_i {S}
scoreboard players operation #tx_b {S} = #tx_i {S}
scoreboard players add #tx_b {S} 1
function {NS}/_cut_ab
data modify storage {T} mp set value {{}}
data modify storage {T} mp.t set from storage {T} tbl
data modify storage {T} mp.c set from storage {T} win
data modify storage {T} ch set from storage {T} win
function {NS}/_case_map with storage {T} mp
data modify storage {T} pc append from storage {T} ch
scoreboard players add #tx_i {S} 1
execute if score #tx_i {S} < #tx_len {S} run function {NS}/case_loop
""")

w("_case_map", f"""
# {NS}/_case_map [MACRO]
# INPUT $(t) table name, $(c) one character (quote and backslash are excluded by safe).
# Leaves ch untouched when the table has no entry for c.
$data modify storage {T} ch set from storage {M} $(t)."$(c)"
""")

# ---------------------------------------------------------------- scans
w("scan_deny", f"""
# {NS}/scan_deny
# INPUT  {T}: s, tbl (name of a table in {M})
# RETURN 1 if any character of s is a key of that table, else 0.
# s must not contain a quote or backslash (check with safe first).
execute store result score #tx_len {S} run data get storage {T} s
scoreboard players set #tx_i {S} 0
scoreboard players set #tx_hit {S} 0
execute if score #tx_len {S} matches 1.. run function {NS}/scan_deny_loop
return run scoreboard players get #tx_hit {S}
""")

w("scan_deny_loop", f"""
# {NS}/scan_deny_loop [INTERNAL]
scoreboard players operation #tx_a {S} = #tx_i {S}
scoreboard players operation #tx_b {S} = #tx_i {S}
scoreboard players add #tx_b {S} 1
function {NS}/_cut_ab
data modify storage {T} mp set value {{}}
data modify storage {T} mp.t set from storage {T} tbl
data modify storage {T} mp.c set from storage {T} win
function {NS}/_deny_probe with storage {T} mp
execute if score #tx_hit {S} matches 1 run return 1
scoreboard players add #tx_i {S} 1
execute if score #tx_i {S} < #tx_len {S} run function {NS}/scan_deny_loop
""")

w("_deny_probe", f"""
# {NS}/_deny_probe [MACRO]
$execute if data storage {M} $(t)."$(c)" run scoreboard players set #tx_hit {S} 1
""")

w("_digit_probe", f"""
# {NS}/_digit_probe [MACRO]
$execute if data storage {M} digit."$(c)" run data modify storage {T} isd set value 1b
""")

w("num_check", f"""
# {NS}/num_check
# INPUT  {T}: s, allow_dot (byte: 1b also accepts one decimal point)
# RETURN 1 when s is a whole number (or decimal), 0 otherwise with err set.
# Accepts an optional leading '-'. A '.' must have digits on both sides.
# No size limit here; to_number adds one.
data remove storage {T} err
execute store result score #tx_len {S} run data get storage {T} s
execute store result score #tx_dotok {S} run data get storage {T} allow_dot
execute if score #tx_len {S} matches 0 run data modify storage {T} err set value "empty input"
execute if score #tx_len {S} matches 0 run return 0
scoreboard players set #tx_a {S} 0
scoreboard players set #tx_b {S} 1
function {NS}/_cut_ab
scoreboard players set #tx_start {S} 0
execute if data storage {T} {{win:"-"}} run scoreboard players set #tx_start {S} 1
execute if score #tx_start {S} >= #tx_len {S} if score #tx_dotok {S} matches 0 run data modify storage {T} err set value "no digits after '-'"
execute if score #tx_start {S} >= #tx_len {S} if score #tx_dotok {S} matches 1 run data modify storage {T} err set value "no digits"
execute if data storage {T} err run return 0
data modify storage {T} needle set value "."
data modify storage {T} n set value 0
execute store result score #tx_dots {S} run function {NS}/find
execute if score #tx_dots {S} matches 2.. run data modify storage {T} err set value "more than one '.'"
execute if score #tx_dots {S} matches 1 if score #tx_dotok {S} matches 0 run data modify storage {T} err set value "contains a non-digit character"
execute if data storage {T} err run return 0
scoreboard players set #tx_dotpos {S} -1
execute if score #tx_dots {S} matches 1 store result score #tx_dotpos {S} run data get storage {T} idx[0]
scoreboard players operation #tx_last {S} = #tx_len {S}
scoreboard players remove #tx_last {S} 1
execute if score #tx_dots {S} matches 1 if score #tx_dotpos {S} = #tx_start {S} run data modify storage {T} err set value "malformed decimal point"
execute if score #tx_dots {S} matches 1 if score #tx_dotpos {S} = #tx_last {S} run data modify storage {T} err set value "malformed decimal point"
execute if data storage {T} err run return 0
scoreboard players operation #tx_i {S} = #tx_start {S}
data modify storage {T} isd set value 1b
execute store result score #tx_r {S} run function {NS}/num_scan_loop
execute if score #tx_r {S} matches 0 run data modify storage {T} err set value "contains a non-digit character"
execute if score #tx_r {S} matches 0 run return 0
return 1
""")

w("num_scan_loop", f"""
# {NS}/num_scan_loop [INTERNAL] every character except the decimal point must be a digit
execute unless score #tx_i {S} < #tx_len {S} run return 1
execute if score #tx_i {S} = #tx_dotpos {S} run scoreboard players add #tx_i {S} 1
execute unless score #tx_i {S} < #tx_len {S} run return 1
scoreboard players operation #tx_a {S} = #tx_i {S}
scoreboard players operation #tx_b {S} = #tx_i {S}
scoreboard players add #tx_b {S} 1
function {NS}/_cut_ab
data modify storage {T} mp set value {{}}
data modify storage {T} mp.c set from storage {T} win
data modify storage {T} isd set value 0b
function {NS}/_digit_probe with storage {T} mp
execute if data storage {T} {{isd:0b}} run return 0
scoreboard players add #tx_i {S} 1
return run function {NS}/num_scan_loop
""")

# ---------------------------------------------------------------- numbers
w("to_number", f"""
# {NS}/to_number
# INPUT  {T}: s (string like "42", "-7", "3.14")
# OUTPUT {T}: out (int or double)   on failure: err, out unset
# RETURN 1 on success, 0 on failure. Whole numbers are limited to 9 digits.
data remove storage {T} out
data modify storage {T} allow_dot set value 1b
execute store result score #tx_ok {S} run function {NS}/num_check
execute if score #tx_ok {S} matches 0 run return 0
scoreboard players operation #tx_digits {S} = #tx_len {S}
scoreboard players operation #tx_digits {S} -= #tx_start {S}
execute if score #tx_dots {S} matches 0 if score #tx_digits {S} matches 10.. run data modify storage {T} err set value "to_number: whole numbers are limited to 9 digits"
execute if score #tx_dots {S} matches 1 if score #tx_digits {S} matches 18.. run data modify storage {T} err set value "to_number: too many digits"
execute if data storage {T} err run return 0
data modify storage {T} arg set value {{}}
data modify storage {T} arg.s set from storage {T} s
function {NS}/_num_emit with storage {T} arg
return 1
""")

w("_num_emit", f"""
# {NS}/_num_emit [MACRO]
# INPUT $(s): a string already validated by num_check (digits, one '-', one '.').
$data modify storage {T} out set value $(s)
""")

w("to_string", f"""
# {NS}/to_string
# INPUT  {T}: in (any value)    OUTPUT {T}: out (string)   or err
# RETURN 1 on success, 0 on failure.
data remove storage {T} err
data remove storage {T} out
execute unless data storage {T} in run data modify storage {T} err set value "to_string: no input"
execute unless data storage {T} in run return 0
data modify storage {T} out set string storage {T} in
return 1
""")

# ---------------------------------------------------------------- tables
def snbt_key(c):
    return '"' + c.replace("\\", "\\\\").replace('"', '\\"') + '"'

lower = {chr(c): chr(c + 32) for c in range(65, 91)}
upper = {v: k for k, v in lower.items()}
digit = {str(d): "1b" for d in range(10)}

# characters rejected inside names (quote, backslash and control characters are handled by find)
deny_name = list(" '{}[]()<>:;,=!@#$%&*+?/|^`~\u00a7")
deny_tag = list(" '{}[]:\u00a7|^<>")

def table(d, val=lambda v: '"' + v + '"'):
    return "{" + ",".join(f"{snbt_key(k)}:{val(v)}" for k, v in d.items()) + "}"

def flags(chars):
    return "{" + ",".join(f"{snbt_key(c)}:1b" for c in chars) + "}"

w("load", f"""
# {NS}/load
# Builds the lookup tables used by the text module (storage {M}).
# Idempotent; called from macroengine:setup.
data modify storage {M} lower set value {table(lower)}
data modify storage {M} upper set value {table(upper)}
data modify storage {M} digit set value {table(digit, lambda v: v)}
data modify storage {M} deny_name set value {flags(deny_name)}
data modify storage {M} deny_tag set value {flags(deny_tag)}
""")

lf, uf = {}, {}
for cp in range(0x20, 0x10000):
    if 0xD800 <= cp <= 0xDFFF or chr(cp) in '"\\':
        continue
    c = chr(cp)
    lo, up = c.lower(), c.upper()
    if len(lo) == 1 and lo != c and lo not in '"\\':
        lf[c] = lo
    if len(up) == 1 and up != c and up not in '"\\':
        uf[c] = up

w("load_full", f"""
# {NS}/load_full
# Full BMP case tables (simple one-to-one mappings from the Unicode character database).
# Loaded lazily the first time lower_full or upper_full is used.
data modify storage {M} lower_full set value {table(lf)}
data modify storage {M} upper_full set value {table(uf)}
data modify storage {M} full set value 1b
""")

w("unload", f"""
# {NS}/unload
# Removes every storage entry owned by the text module.
data remove storage {T} s
data remove storage {T} out
data remove storage {T} err
data remove storage {M} lower
data remove storage {M} upper
data remove storage {M} digit
data remove storage {M} deny_name
data remove storage {M} deny_tag
data remove storage {M} lower_full
data remove storage {M} upper_full
data remove storage {M} full
function {NS}/reset
""")

print("text module written:", len(os.listdir(BASE)), "files; full tables:", len(lf), "/", len(uf))
