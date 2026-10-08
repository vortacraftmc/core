# ─────────────────────────────────────────────────────────────────
# macroengine:systems/text/show_to [MACRO]
# As systems/text/show, but to an arbitrary selector.
#
# INPUT: $(storage), $(path), $(target)
#
# Usage:  function macroengine:systems/text/show_to {storage:"macroengine:engine",path:"flags",target:"@a[tag=macroengine.admin]"}
# ─────────────────────────────────────────────────────────────────

$tellraw $(target) [{"text":"[MACROENGINE] ","color":"#00AAAA","bold":true},{"storage":"$(storage)","nbt":"$(path)","plain":true,"interpret":false,"color":"white"}]
