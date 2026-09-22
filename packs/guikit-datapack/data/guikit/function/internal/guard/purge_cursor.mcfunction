# macro: $(own)
$execute if items entity @s player.cursor *[custom_data~{guikit:{w:1b}}] unless items entity @s player.cursor *[custom_data~{guikit:{own:$(own)}}] run function guikit:internal/guard/purge_hit {slot:"player.cursor"}
