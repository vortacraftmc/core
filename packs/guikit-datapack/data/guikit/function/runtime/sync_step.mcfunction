# guikit :: runtime/sync_step
execute unless data storage guikit:work order[0] run return 0
data modify storage guikit:work id set from storage guikit:work order[0]
function guikit:runtime/sync_one with storage guikit:work
data remove storage guikit:work order[0]
function guikit:runtime/sync_step
