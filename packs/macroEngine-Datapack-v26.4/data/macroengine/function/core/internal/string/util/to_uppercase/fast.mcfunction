# ============================================================================
# FIXED: zprivate/to_uppercase/main_fast is now implemented macroEngine-native
# (algorithm after CMDred's StringLib, macroengine storage paths).
# ============================================================================


##########################################################################################################
##                                              HOW TO USE                                              ##
##########################################################################################################
## 1. Run this function with the 'String' macro variable set to what you want to convert to uppercase   ##
##    Note: This function only covers the letters A-Z, but is noticeably faster in return               ##
##                                                                                                      ##
## Output: Uppercase version of your input                                                              ##
##         Example: "abc" => "ABC"                                                                      ##
##                                                                                                      ##
## The output is found in the 'macroengine:core/internal/string/output to_uppercase' data storage                              ##
##########################################################################################################

# Setup
$data modify storage macroengine:core/internal/string/temp data.Input set value "$(String)"
execute store result score #StringLib.CharsLeft StringLib run data get storage macroengine:core/internal/string/temp data.Input
data modify storage macroengine:core/internal/string/temp data.Char set string storage macroengine:core/internal/string/temp data.Input 0 1

data modify storage macroengine:core/internal/string/temp data.CharList set value []

# Uppercase each character
function macroengine:core/internal/string/zprivate/to_uppercase/main_fast with storage macroengine:core/internal/string/temp data

# Combine the characters again
data modify storage macroengine:core/internal/string/temp data2.PrevInput set from storage macroengine:core/internal/string/input concat
data modify storage macroengine:core/internal/string/temp data2.PrevOutput set from storage macroengine:core/internal/string/output concat

data modify storage macroengine:core/internal/string/input concat set from storage macroengine:core/internal/string/temp data.CharList
function macroengine:core/internal/string/util/concat
data modify storage macroengine:core/internal/string/output to_uppercase set from storage macroengine:core/internal/string/output concat

data modify storage macroengine:core/internal/string/input concat set from storage macroengine:core/internal/string/temp data2.PrevInput
data modify storage macroengine:core/internal/string/output concat set from storage macroengine:core/internal/string/temp data2.PrevOutput
execute unless data storage macroengine:core/internal/string/temp data2.PrevInput run data remove storage macroengine:core/internal/string/input concat
execute unless data storage macroengine:core/internal/string/temp data2.PrevOutput run data remove storage macroengine:core/internal/string/output concat

# Reset
data remove storage macroengine:core/internal/string/temp data2
