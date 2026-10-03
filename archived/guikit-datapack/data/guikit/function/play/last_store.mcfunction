# guikit :: play/last_store   macro: $(pid)
# Writes guikit:ctx last into the per-player slot guikit:mem last.m<pid>.
$data modify storage guikit:mem last.m$(pid) set from storage guikit:ctx last
