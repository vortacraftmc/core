# macroengine:setup — ordered load sequence (the old fake percentage output was removed:
# it printed 20+ console lines per load and reported nothing real).

# Initialization

# Step 1: Internal Text Module
function macroengine:core/internal/text/load
function macroengine:api/placeholder/load

# Step 2: Player Enumeration
function macroengine:core/internal/player/enumerate

# Step 3: Player Resolution
function macroengine:core/internal/player/resolve

# Step 4: Player Initialization
function macroengine:core/internal/player/init

# Step 4b: Player events (join, death, jump, enchant, clicks, GUI blocks)
function macroengine:core/internal/pev/load

# Step 5: Core Main Load
function macroengine:core/internal/load/main

# Completion
execute unless entity @a run say [MacroEngine] loaded
