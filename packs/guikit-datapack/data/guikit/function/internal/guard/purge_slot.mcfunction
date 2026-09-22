# macro: $(i) $(own)
$execute if items entity @s container.$(i) *[custom_data~{guikit:{w:1b}}] unless items entity @s container.$(i) *[custom_data~{guikit:{own:$(own)}}] run function guikit:internal/guard/purge_hit {slot:"container.$(i)"}
