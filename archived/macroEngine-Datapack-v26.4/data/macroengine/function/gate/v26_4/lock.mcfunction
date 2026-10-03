# macroengine:gate/v26_4/lock - emergency kill switch (Gate 3). Needs function permission (op).
# Tick, load entries and the guarded macro sinks stay inert until unlock.
data modify storage macroengine:gate/v26_4 state set value "locked"
data modify storage macroengine:gate/v26_4 reason set value "manual lockdown"
say [macroEngine] LOCKDOWN engaged: tick, load and guarded command sinks are disabled. Re-enable with macroengine:gate/v26_4/unlock
