# rtwrapper:gate/r1_21_1/lock - emergency kill switch (Gate 3). Needs function permission (op).
# Tick, load entries and the guarded macro sinks stay inert until unlock.
data modify storage rtwrapper:gate/r1_21_1 state set value "locked"
data modify storage rtwrapper:gate/r1_21_1 reason set value "manual lockdown"
say [RTWrapper] LOCKDOWN engaged: tick, load and guarded command sinks are disabled. Re-enable with rtwrapper:gate/r1_21_1/unlock
