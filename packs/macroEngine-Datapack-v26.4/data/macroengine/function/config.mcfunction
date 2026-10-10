# macroengine:config
# Single source of runtime configuration (replaces _rt_origin + scattered defaults).
# Other packs may read macroengine:engine config / macroengine.meta scores; do not hardcode.

# ── Version (264 = 26.4) ──────────────────────────────────────────
scoreboard objectives add macroengine.meta dummy
scoreboard players set #vortacraftmc.packs.macroengine.version macroengine.meta 264

# Archived flag: set to 1 to show archive warning on every /reload
# scoreboard players set #vortacraftmc.archivedpacks.macroengine macroengine.meta 1
execute unless score #vortacraftmc.archivedpacks.macroengine macroengine.meta matches -2147483648..2147483647 run scoreboard players set #vortacraftmc.archivedpacks.macroengine macroengine.meta 1

# ── Engine defaults (only fill missing keys — preserves live data) ─
execute unless data storage macroengine:engine global run data modify storage macroengine:engine global set value {}
data modify storage macroengine:engine global.version set value "v26.4-snapshot-1"

execute unless data storage macroengine:engine config run data modify storage macroengine:engine config set value {}

# Feature toggles (override via /data modify storage macroengine:engine config.*)
execute unless data storage macroengine:engine config.enabled run data modify storage macroengine:engine config.enabled set value 1b
execute unless data storage macroengine:engine config.log_level run data modify storage macroengine:engine config.log_level set value 1
execute unless data storage macroengine:engine config.reload_warn run data modify storage macroengine:engine config.reload_warn set value 1b
execute unless data storage macroengine:engine config.namespace_allowlist run data modify storage macroengine:engine config.namespace_allowlist set value ["macroengine:"]

# No permission gate exists in this pack (see core/internal/load/loader/storages
# for the remaining, non-gate security. fields: sandbox_allowlist,
# multi_type_allowlist).
execute unless data storage macroengine:engine security run data modify storage macroengine:engine security set value {}

# Generic flag storage used by systems/flag/*.
execute unless data storage macroengine:engine flags run data modify storage macroengine:engine flags set value {}
