# macroEngine string module — split: separator not found.
# Called via `return run` from util/split when find reports [-1]. The output
# list stays empty (as initialized by util/split) and the failure status is
# propagated to the original caller.

return fail
