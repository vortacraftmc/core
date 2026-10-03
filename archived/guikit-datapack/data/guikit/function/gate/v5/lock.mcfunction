# guikit:gate/v5/lock - emergency kill switch (Gate 3). Needs function permission (op).
# Tick, load entries and the guarded macro sinks stay inert until unlock.
data modify storage guikit:gate/v5 state set value "locked"
data modify storage guikit:gate/v5 reason set value "manual lockdown"
say [guikit] LOCKDOWN engaged: tick, load and guarded command sinks are disabled. Re-enable with guikit:gate/v5/unlock
