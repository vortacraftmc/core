# One issue. Runs as a macro over a single element of the `issues` list, so the
# fields arrive already substituted.
#
# The values come from GitHub and are therefore attacker-controlled - anyone
# can open an issue. packd escapes them before they reach storage (see
# packd.issues.snbt_string and its injection tests), so a quote or a newline in
# a title cannot end the string and start a second command. This function adds
# no further untrusted data.
#
# `open_url` requires a valid http(s) URI in 1.21.5+; an issue URL always is.
$tellraw @a [{"text":"  ","color":"dark_gray"},{"text":"#$(number)","color":"gold"},{"text":" ","color":"dark_gray"},{"text":"$(title)","color":"white","click_event":{"action":"open_url","url":"$(url)"},"hover_event":{"action":"show_text","value":[{"text":"$(title)","color":"white","bold":true},{"text":"\n\nby $(author)  |  updated $(updated)","color":"gray"},{"text":"\nlabels: $(labels)","color":"dark_gray"},{"text":"\n\n$(preview)","color":"yellow"},{"text":"\n\n$(url)","color":"dark_gray","underlined":true}]}},{"text":" ","color":"dark_gray"},{"text":"$(author)","color":"dark_gray"}]
