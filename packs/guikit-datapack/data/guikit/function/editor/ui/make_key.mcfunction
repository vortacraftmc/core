# key suffix m<n>_<page>_<slot> — per-player prefix is added at click time
execute store result score #n guikit.tmp run data get storage guikit:work menu.n
execute store result score #page guikit.tmp run data get storage guikit:ed cur.page
execute store result score #slot guikit.tmp run data get storage guikit:ed cur.slot
execute store result storage guikit:work n int 1 run scoreboard players get #n guikit.tmp
execute store result storage guikit:work page int 1 run scoreboard players get #page guikit.tmp
execute store result storage guikit:work slot int 1 run scoreboard players get #slot guikit.tmp
function guikit:editor/ui/make_key_do with storage guikit:work
