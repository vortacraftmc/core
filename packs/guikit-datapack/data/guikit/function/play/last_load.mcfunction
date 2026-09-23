# guikit :: play/last_load   macro: $(pid)
# Reads the per-player slot guikit:mem last.m<pid> into guikit:ctx last.
# A missing slot (player never opened a menu) fails silently and leaves ctx last unset.
$data modify storage guikit:ctx last set from storage guikit:mem last.m$(pid)
