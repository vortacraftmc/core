# macro: $(uid) $(mode) $(menu) $(alias)
$data modify storage guikit:sess bound.u$(uid) set value {mode:"$(mode)",menu:"$(menu)",alias:"$(alias)"}
